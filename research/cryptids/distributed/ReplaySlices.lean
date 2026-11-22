/-
Proof-of-concept: recheck a small declaration closure from inert exports
instead of importing worker .olean files. Not a low-memory RH checker.
Built against lean4export v4.33.0 (15f6055e299ad5b89345e533cc2192f4cc00f659)
and Lean 4.33.1 (819816b2e0a3bf405af45ae5c7af2491d8f5bee6).
-/
import Export.Parse
import Lean.Replay
import Lean.Util.FoldConsts
import Lean.Data.Json.FromToJson.Basic

open Lean

abbrev DeclMap := Std.HashMap Name ConstantInfo

def trustedAxiom (n : Name) : Bool :=
  n == `propext || n == `Classical.choice || n == `Quot.sound

def equalQuotKind : QuotKind → QuotKind → Bool
  | .type, .type | .ctor, .ctor | .lift, .lift | .ind, .ind => true
  | _, _ => false

def sameDeclaration : ConstantInfo → ConstantInfo → Bool
  | .axiomInfo a, .axiomInfo b => a == b
  | .thmInfo a, .thmInfo b => a == b
  | .defnInfo a, .defnInfo b => a == b
  | .opaqueInfo a, .opaqueInfo b => a == b
  | .ctorInfo a, .ctorInfo b => a == b
  | .recInfo a, .recInfo b => a == b
  | .quotInfo a, .quotInfo b => a.toConstantVal == b.toConstantVal && equalQuotKind a.kind b.kind
  | .inductInfo a, .inductInfo b =>
    a.toConstantVal == b.toConstantVal && a.numParams == b.numParams &&
    a.numIndices == b.numIndices && a.all == b.all && a.ctors == b.ctors &&
    a.numNested == b.numNested && a.isRec == b.isRec && a.isUnsafe == b.isUnsafe &&
    a.isReflexive == b.isReflexive
  | _, _ => false

def fail {α : Type} (reason : String) : IO α := throw (IO.userError reason)

def jsonField (j : Json) (key : String) : IO Json :=
  match j.getObjVal? key with
  | .ok v => pure v
  | .error e => fail e

def jsonString (j : Json) (key : String) : IO String := do
  match (← jsonField j key).getStr? with
  | .ok v => pure v
  | .error e => fail e

def readSlice (path : String) : IO Export.ExportedEnv := do
  let md ← (System.FilePath.mk path).metadata
  if md.byteSize > 64 * 1024 * 1024 then fail "individual pilot export exceeds 64 MiB"
  let h ← IO.FS.Handle.mk path .read
  let stream := IO.FS.Stream.ofHandle h
  let first ← stream.getLine
  let .ok j := Json.parse first | fail "invalid export metadata"
  let metadata ← jsonField j "meta"
  unless (← jsonString (← jsonField metadata "format") "version") == "3.1.0" do
    fail "unexpected export format"
  let l ← jsonField metadata "lean"
  unless (← jsonString l "version") == "4.33.1" &&
         (← jsonString l "githash") == "819816b2e0a3bf405af45ae5c7af2491d8f5bee6" do
    fail "unexpected Lean version or commit"
  let exporter ← jsonField metadata "exporter"
  unless (← jsonString exporter "name") == "lean4export" &&
         (← jsonString exporter "version") == "3.1.0" do
    fail "unexpected exporter"
  let (_, s) ← Export.Parse.M.run Export.Parse.parseItems stream
  pure { constMap := s.constMap, constOrder := s.constOrder }

def integrate (base : DeclMap) (part : Export.ExportedEnv) (holes : List Name) : IO DeclMap := do
  let mut seen : List Name := []
  let mut out := base
  for k in part.constOrder do
    let some dc := part.constMap[k]? | fail s!"missing parsed declaration: {k}"
    if dc.isUnsafe || dc.isPartial then fail s!"unsafe or partial declaration: {k}"
    if holes.contains k then
      let .axiomInfo a := dc | fail s!"expected an explicitly declared proof boundary: {k}"
      let some (.thmInfo p) := base[k]? | fail s!"missing theorem predecessor: {k}"
      unless a.toConstantVal == p.toConstantVal do fail s!"boundary type mismatch: {k}"
      seen := k :: seen
    else
      if let .axiomInfo _ := dc then
        unless trustedAxiom k do fail s!"unapproved axiom: {k}"
      match out[k]? with
      | some prev =>
        unless sameDeclaration prev dc do fail s!"conflicting declaration: {k}"
      | none =>
        out := out.insert k dc
  for hole in holes do
    unless seen.contains hole do fail s!"expected boundary not present: {hole}"
  pure out

def rootAndHoles (mode : String) : IO (Name × List Name) :=
  match mode with
  | "cube" => pure (`CubePrime.Pratt.pilotFinitePrefix,
                    [`CubePrime.Pratt.group_000, `CubePrime.Pratt.group_001])
  | "tiny" => pure (`SlicePilot.output, [`SlicePilot.input])
  | "core" => pure (`CubePrime.Pratt.splice, [])
  | _ => fail "expected mode cube, tiny, or core"

def declDependencies (ci : ConstantInfo) : Array Name :=
  let ordinary := ci.getUsedConstantsAsSet.toArray
  match ci with
  | .inductInfo i => ordinary ++ i.all.toArray ++ i.ctors.toArray
  | .ctorInfo c => ordinary.push c.induct
  | .recInfo r =>
    r.rules.foldl (fun deps rule => deps.push rule.ctor ++ rule.rhs.getUsedConstants)
      (ordinary ++ r.all.toArray)
  | _ => ordinary

def matchClosure (label : String) (expected actual : Name → Option ConstantInfo)
    (initial : Array Name) : IO Unit := do
  let mut queue := initial
  let mut seen : NameSet := {}
  let mut i := 0
  while i < queue.size do
    let n := queue[i]!
    i := i + 1
    if !seen.contains n then
      seen := seen.insert n
      if n == `sorryAx then fail s!"unsupported {label} dependency: {n}"
      let some known := expected n | fail s!"{label} declaration missing: {n}"
      let some got := actual n | fail s!"missing {label} dependency: {n}"
      unless sameDeclaration known got do fail s!"{label} dependency mismatch: {n}"
      queue := queue ++ declDependencies known

def trustedInit : IO Environment :=
  -- LEAN_PATH is isolated by the runner. Init must be from the pinned official
  -- Lean distribution. No worker object is loaded by this application.
  importModules #[{ module := `Init }] {}

def validateCoreAxioms (init : Environment) (declarations : Name → Option ConstantInfo) : IO Unit := do
  let mut seeds := #[]
  for n in [`propext, `Classical.choice, `Quot.sound] do
    if let some got := declarations n then
      let some (.axiomInfo expected) := init.find? n | fail s!"missing trusted core axiom: {n}"
      unless sameDeclaration (.axiomInfo expected) got do
        fail s!"wrong type or declaration kind for trusted core axiom: {n}"
      seeds := seeds.push n
  -- A canonical signature can otherwise refer to a counterfeit Nonempty/Eq.
  matchClosure "trusted core" (init.find? ·) declarations seeds

def checkChallenge (root : Name) (data : Export.ExportedEnv)
    (declarations : Name → Option ConstantInfo) : IO Unit := do
  let some (.thmInfo expected) := data.constMap[root]? | fail s!"challenge has no theorem: {root}"
  let some (.thmInfo actual) := declarations root | fail s!"solution has no theorem: {root}"
  unless expected.toConstantVal == actual.toConstantVal do fail s!"root statement mismatch: {root}"
  -- The isolated challenge proof (a temporary sorry) is never replayed.
  matchClosure "challenge" (data.constMap[·]?) declarations expected.type.getUsedConstants

def main (args : List String) : IO Unit := do
  let mode :: challenge :: rest := args | fail "usage: ReplaySlices.lean MODE CHALLENGE PREDECESSOR... CONSUMER"
  let some consumer := rest.getLast? | fail "missing consumer export"
  if rest.length > 3 then fail "pilot supports at most two predecessors and one consumer"
  let (root, holes) ← rootAndHoles mode
  let mut declarations : DeclMap := {}
  for predecessor in rest.dropLast do
    let data ← readSlice predecessor
    declarations ← integrate declarations data []
  let data ← readSlice consumer
  let some (.thmInfo proof) := data.constMap[root]? | fail s!"consumer does not provide theorem: {root}"
  declarations ← integrate declarations data holes
  for n in holes do
    unless proof.value.getUsedConstantsAsSet.contains n do fail s!"consumer proof does not use boundary: {n}"
  let init ← trustedInit
  let specification ← readSlice challenge
  validateCoreAxioms init (declarations[·]?)
  checkChallenge root specification (declarations[·]?)
  let k ← (← mkEmptyEnvironment 0).replay declarations
  let some (.thmInfo checked) := k.toKernelEnv.find? root | fail s!"kernel did not produce theorem: {root}"
  unless checked.toConstantVal == proof.toConstantVal do fail s!"replayed theorem type changed: {root}"
  validateCoreAxioms init k.toKernelEnv.find?
  checkChallenge root specification k.toKernelEnv.find?
  IO.println s!"KERNEL_REPLAY_PASS proof={root} declarations={declarations.size} discharged={holes.length}"
