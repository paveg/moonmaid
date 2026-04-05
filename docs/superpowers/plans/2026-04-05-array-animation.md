# Array Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `@animate` support to array diagrams with 4 sort algorithm visualizations (bubble, insertion, selection, quick).

**Architecture:** Extend the parser to accept `array @animate { [...] sort: <algo> }`. Add new types (`SortAlgorithm`, `ArrayAnimDef`). Implement each sort as a function that produces `AnimationTimeline` using existing `AnimationAction` variants. The existing `render_animated` + grid layout pipeline handles rendering without modification.

**Tech Stack:** MoonBit (sort animation logic), existing animation/renderer/parser packages

**Spec:** `docs/superpowers/specs/2026-04-05-array-animation-design.md`

**Prerequisite:** 106 MoonBit tests passing on main

---

## File Structure

```
src/
├── types/
│   └── types.mbt              # MODIFY: add SortAlgorithm, ArrayAnimDef, extend Diagram
├── parser/
│   ├── token.mbt              # MODIFY: add TkSort, TkBubble, TkInsertion, TkSelection, TkQuick
│   ├── lexer.mbt              # MODIFY: add keywords to keyword_token
│   ├── lexer_test.mbt         # MODIFY: add token tests
│   ├── parser.mbt             # MODIFY: parse array @animate { [...] sort: <algo> }
│   └── parser_test.mbt        # MODIFY: add parse tests
├── animation/
│   ├── sort.mbt               # NEW: sort animation generators (all 4 algorithms)
│   └── sort_test.mbt          # NEW: sort animation tests
├── lib/
│   ├── moonmaid.mbt           # MODIFY: handle AnimatedArrayDiagram in render_result
│   └── moonmaid_test.mbt      # MODIFY: add e2e tests
```

---

### Task 1: Types — SortAlgorithm, ArrayAnimDef, Diagram extension

**Files:**
- Modify: `src/types/types.mbt`

- [ ] **Step 1: Write failing test**

Append to `src/types/types_test.mbt`:
```moonbit
test "construct ArrayAnimDef" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 4],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  assert_eq(def.elements, [3, 1, 4])
  assert_eq(def.algorithm, @types.SortAlgorithm::Bubble)
}

test "all SortAlgorithm variants" {
  let variants : Array[@types.SortAlgorithm] = [
    @types.SortAlgorithm::Bubble,
    @types.SortAlgorithm::Insertion,
    @types.SortAlgorithm::Selection,
    @types.SortAlgorithm::Quick,
  ]
  assert_eq(variants.length(), 4)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test --target wasm-gc -p paveg/moonmaid/types`
Expected: FAIL — `ArrayAnimDef` not defined

- [ ] **Step 3: Add types to types.mbt**

Append to `src/types/types.mbt`:
```moonbit
///| Sort algorithm for array animation.
pub(all) enum SortAlgorithm {
  Bubble
  Insertion
  Selection
  Quick
} derive(Show, Eq)

///| Array animation definition.
pub(all) struct ArrayAnimDef {
  elements : Array[Int]
  algorithm : SortAlgorithm
} derive(Show, Eq)
```

Extend the `Diagram` enum — add `AnimatedArrayDiagram(ArrayAnimDef)` variant.

Also update `src/lib/moonmaid.mbt` to handle the new variant in the match (add a temporary placeholder that returns an error SVG, to be replaced in Task 6).

- [ ] **Step 4: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc
moon fmt
git add src/types/ src/lib/moonmaid.mbt
git commit -m "feat: add SortAlgorithm, ArrayAnimDef types and Diagram variant"
```

---

### Task 2: Lexer — sort algorithm tokens

**Files:**
- Modify: `src/parser/token.mbt`
- Modify: `src/parser/lexer.mbt`
- Modify: `src/parser/lexer_test.mbt`

- [ ] **Step 1: Write failing tests**

Append to `src/parser/lexer_test.mbt`:
```moonbit
test "lex array @animate sort bubble" {
  let input = "array @animate { [3, 1] sort: bubble }"
  let tokens = @parser.lex(input)
  let kinds : Array[@parser.Token] = tokens.map(fn(t) { t.token })
  assert_eq(kinds, [
    @parser.Token::TkArray, @parser.Token::At, @parser.Token::TkAnimate,
    @parser.Token::LBrace,
    @parser.Token::LBracket, @parser.Token::IntLit(3), @parser.Token::Comma,
    @parser.Token::IntLit(1), @parser.Token::RBracket,
    @parser.Token::TkSort, @parser.Token::Colon,
    @parser.Token::TkBubble,
    @parser.Token::RBrace, @parser.Token::Eof,
  ])
}

test "lex all sort algorithm keywords" {
  for kw in ["bubble", "insertion", "selection", "quick"] {
    let tokens = @parser.lex(kw)
    let tok = tokens[0].token
    match tok {
      @parser.Token::TkBubble | @parser.Token::TkInsertion |
      @parser.Token::TkSelection | @parser.Token::TkQuick => ()
      _ => fail("Expected sort keyword token for \{kw}, got \{tok}")
    }
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: FAIL — `TkSort`, `Colon`, `TkBubble` not defined

- [ ] **Step 3: Add tokens and lexer support**

In `src/parser/token.mbt`, add to Token enum:
```moonbit
  TkSort       // sort
  TkBubble     // bubble
  TkInsertion  // insertion
  TkSelection  // selection
  TkQuick      // quick
  Colon        // :
```

In `src/parser/lexer.mbt`, add to `keyword_token`:
```moonbit
    "sort" => Some(TkSort)
    "bubble" => Some(TkBubble)
    "insertion" => Some(TkInsertion)
    "selection" => Some(TkSelection)
    "quick" => Some(TkQuick)
```

Add `:` to the `next_token` match:
```moonbit
    Some(':') => { self.advance(); Colon }
```

- [ ] **Step 4: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/parser
moon fmt
git add src/parser/
git commit -m "feat: add sort algorithm tokens and colon to lexer"
```

---

### Task 3: Parser — array @animate { [...] sort: algo }

**Files:**
- Modify: `src/parser/parser.mbt`
- Modify: `src/parser/parser_test.mbt`

- [ ] **Step 1: Write failing tests**

Append to `src/parser/parser_test.mbt`:
```moonbit
test "parse array @animate bubble sort" {
  let input = "array @animate { [3, 1, 4] sort: bubble }"
  match @parser.parse(input) {
    @types.Diagram::AnimatedArrayDiagram(def) => {
      assert_eq(def.elements, [3, 1, 4])
      assert_eq(def.algorithm, @types.SortAlgorithm::Bubble)
    }
    _ => fail("Expected AnimatedArrayDiagram")
  }
}

test "parse array @animate all sort algorithms" {
  let algos = ["bubble", "insertion", "selection", "quick"]
  let expected = [
    @types.SortAlgorithm::Bubble,
    @types.SortAlgorithm::Insertion,
    @types.SortAlgorithm::Selection,
    @types.SortAlgorithm::Quick,
  ]
  for i = 0; i < algos.length(); i = i + 1 {
    let input = "array @animate { [1, 2] sort: \{algos[i]} }"
    match @parser.parse(input) {
      @types.Diagram::AnimatedArrayDiagram(def) => {
        assert_eq(def.algorithm, expected[i])
      }
      _ => fail("Expected AnimatedArrayDiagram for \{algos[i]}")
    }
  }
}

test "parse array @animate missing sort errors" {
  let result : Result[Unit, Unit] = try {
    let _ = @parser.parse("array @animate { [1, 2] }")
    Ok(())
  } catch { _ => Err(()) }
  assert_eq(result, Err(()))
}

test "parse array @animate unknown sort algorithm errors" {
  let result : Result[Unit, Unit] = try {
    let _ = @parser.parse("array @animate { [1, 2] sort: merge }")
    Ok(())
  } catch { _ => Err(()) }
  assert_eq(result, Err(()))
}

test "parse static array unchanged" {
  let input = "array { [3, 1, 4] }"
  match @parser.parse(input) {
    @types.Diagram::ArrayDiagram(def) => assert_eq(def.elements, [3, 1, 4])
    _ => fail("Expected static ArrayDiagram")
  }
}

test "parse array @animate empty array" {
  let input = "array @animate { [] sort: bubble }"
  match @parser.parse(input) {
    @types.Diagram::AnimatedArrayDiagram(def) => {
      assert_eq(def.elements, [])
      assert_eq(def.algorithm, @types.SortAlgorithm::Bubble)
    }
    _ => fail("Expected AnimatedArrayDiagram")
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/parser`
Expected: FAIL — AnimatedArrayDiagram not produced

- [ ] **Step 3: Implement parser changes**

In `src/parser/parser.mbt`, modify the `TkArray` branch of `parse_diagram`:

```moonbit
TkArray => {
  let _ = self.advance()  // consume TkArray
  // Check for @animate
  if self.peek() == At {
    let _ = self.advance()  // consume @
    match self.advance() {
      TkAnimate => ()
      other => raise @types.MoonmaidError::of("Expected 'animate' after @, got \{other}")
    }
    // Parse animated array: { [...] sort: algo }
    self.expect(LBrace)
    // Parse elements
    self.expect(LBracket)
    let elements : Array[Int] = []
    while self.peek() != RBracket {
      if elements.length() > 0 { self.expect(Comma) }
      elements.push(self.expect_int())
    }
    self.expect(RBracket)
    if elements.length() > self.limits.max_array_size {
      raise @types.MoonmaidError::of(
        "Array size \{elements.length()} exceeds limit (max: \{self.limits.max_array_size})"
      )
    }
    // Parse sort: algo
    self.expect(TkSort)
    self.expect(Colon)
    let algorithm = match self.advance() {
      TkBubble => @types.SortAlgorithm::Bubble
      TkInsertion => @types.SortAlgorithm::Insertion
      TkSelection => @types.SortAlgorithm::Selection
      TkQuick => @types.SortAlgorithm::Quick
      other => raise @types.MoonmaidError::of("Unknown sort algorithm: \{other}")
    }
    self.expect(RBrace)
    self.expect_eof()
    @types.Diagram::AnimatedArrayDiagram({ elements, algorithm })
  } else {
    // Static array (existing code)
    @types.Diagram::ArrayDiagram(self.parse_array())
  }
}
```

NOTE: Read the current parser.mbt first. The `parse_array` function may already handle element parsing. Reuse shared logic where possible. The key addition is: after reading elements, read `sort:` + algorithm token.

- [ ] **Step 4: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc
moon fmt
git add src/parser/
git commit -m "feat: parse array @animate with sort algorithm"
```

---

### Task 4: Bubble Sort + Insertion Sort Animation

**Files:**
- Create: `src/animation/sort.mbt`
- Create: `src/animation/sort_test.mbt`

- [ ] **Step 1: Write failing tests**

Create `src/animation/sort_test.mbt`:
```moonbit
test "bubble sort animation on [3, 1, 2]" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 2],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  // Bubble sort on [3,1,2]:
  // Pass 1: compare(3,1)->swap, compare(3,2)->swap → [1,2,3]
  // Pass 2: compare(1,2)->no swap → done
  // Each comparison = 2 steps (highlight+compare, then swap or unhighlight)
  // Plus final "sorted" highlights
  assert_true(timeline.steps.length() > 0)
  // First step should be a comparison
  assert_true(timeline.steps[0].description.contains("Compare"))
}

test "bubble sort already sorted" {
  let def : @types.ArrayAnimDef = {
    elements: [1, 2, 3],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  // Still generates comparison steps (checks all pairs)
  assert_true(timeline.steps.length() > 0)
  // No SwapNodes actions since no swaps needed
  let has_swap = timeline.steps.iter().any(fn(step) {
    step.actions.iter().any(fn(a) {
      match a { @types.AnimationAction::SwapNodes(..) => true; _ => false }
    })
  })
  assert_false(has_swap)
}

test "bubble sort empty array" {
  let def : @types.ArrayAnimDef = {
    elements: [],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

test "bubble sort single element" {
  let def : @types.ArrayAnimDef = {
    elements: [42],
    algorithm: @types.SortAlgorithm::Bubble,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

test "insertion sort animation on [3, 1, 2]" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 2],
    algorithm: @types.SortAlgorithm::Insertion,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  // Insertion sort should mention "Insert" in descriptions
  assert_true(timeline.steps.iter().any(fn(s) { s.description.contains("Insert") }))
}

test "insertion sort empty array" {
  let def : @types.ArrayAnimDef = {
    elements: [],
    algorithm: @types.SortAlgorithm::Insertion,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/animation`
Expected: FAIL — `generate_sort_animation` not defined

- [ ] **Step 3: Implement bubble sort and insertion sort**

Create `src/animation/sort.mbt`:
```moonbit
///| Generate animation timeline for a sort algorithm.
pub fn generate_sort_animation(
  def : @types.ArrayAnimDef,
  _config : @types.LayoutConfig,
) -> @types.AnimationTimeline {
  match def.algorithm {
    Bubble => generate_bubble_sort(def.elements)
    Insertion => generate_insertion_sort(def.elements)
    Selection => generate_selection_sort(def.elements)
    Quick => generate_quick_sort(def.elements)
  }
}

///| Node ID for array element at index i.
fn elem_id(i : Int) -> String {
  "elem_\{i}"
}

///| Generate bubble sort animation.
fn generate_bubble_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 { return { steps: [] } }
  let arr = elements.copy()
  let steps : Array[@types.AnimationStep] = []
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - 1 - i; j = j + 1 {
      // Highlight and compare
      steps.push({
        actions: [
          @types.AnimationAction::Highlight(node_id=elem_id(j), color="blue"),
          @types.AnimationAction::Highlight(node_id=elem_id(j + 1), color="blue"),
          @types.AnimationAction::CompareNodes(a=arr[j].to_string(), b=arr[j + 1].to_string()),
        ],
        description: "Compare \{arr[j]} and \{arr[j + 1]}",
        duration_ms: 300,
      })
      if arr[j] > arr[j + 1] {
        // Swap
        let tmp = arr[j]
        arr[j] = arr[j + 1]
        arr[j + 1] = tmp
        steps.push({
          actions: [
            @types.AnimationAction::SwapNodes(a=elem_id(j), b=elem_id(j + 1)),
            @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
            @types.AnimationAction::Unhighlight(node_id=elem_id(j + 1)),
          ],
          description: "Swap \{arr[j + 1]} and \{arr[j]}",
          duration_ms: 400,
        })
      } else {
        // No swap needed
        steps.push({
          actions: [
            @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
            @types.AnimationAction::Unhighlight(node_id=elem_id(j + 1)),
          ],
          description: "No swap needed",
          duration_ms: 200,
        })
      }
    }
    // Mark sorted position
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(n - 1 - i), color="green"),
      ],
      description: "\{arr[n - 1 - i]} is in sorted position",
      duration_ms: 200,
    })
  }
  // Mark first element as sorted
  steps.push({
    actions: [
      @types.AnimationAction::Highlight(node_id=elem_id(0), color="green"),
    ],
    description: "Sort complete",
    duration_ms: 200,
  })
  { steps }
}

///| Generate insertion sort animation.
fn generate_insertion_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 { return { steps: [] } }
  let arr = elements.copy()
  let steps : Array[@types.AnimationStep] = []
  // First element is trivially sorted
  steps.push({
    actions: [
      @types.AnimationAction::Highlight(node_id=elem_id(0), color="green"),
    ],
    description: "\{arr[0]} is trivially sorted",
    duration_ms: 200,
  })
  for i = 1; i < n; i = i + 1 {
    let key = arr[i]
    // Highlight the element to insert
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="yellow"),
      ],
      description: "Insert \{key} into sorted portion",
      duration_ms: 300,
    })
    let mut j = i - 1
    while j >= 0 && arr[j] > key {
      // Compare
      steps.push({
        actions: [
          @types.AnimationAction::Highlight(node_id=elem_id(j), color="blue"),
          @types.AnimationAction::CompareNodes(a=arr[j].to_string(), b=key.to_string()),
        ],
        description: "\{arr[j]} > \{key}, shift right",
        duration_ms: 300,
      })
      // Shift (swap adjacent)
      arr[j + 1] = arr[j]
      steps.push({
        actions: [
          @types.AnimationAction::SwapNodes(a=elem_id(j), b=elem_id(j + 1)),
          @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
        ],
        description: "Shift \{arr[j + 1]} right",
        duration_ms: 300,
      })
      j = j - 1
    }
    arr[j + 1] = key
    // Place key
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(j + 1), color="green"),
      ],
      description: "\{key} placed at position \{j + 1}",
      duration_ms: 200,
    })
  }
  { steps }
}

///| Placeholder for selection sort — implemented in Task 5.
fn generate_selection_sort(_elements : Array[Int]) -> @types.AnimationTimeline {
  { steps: [] }
}

///| Placeholder for quick sort — implemented in Task 5.
fn generate_quick_sort(_elements : Array[Int]) -> @types.AnimationTimeline {
  { steps: [] }
}
```

- [ ] **Step 4: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/animation
moon fmt
git add src/animation/sort.mbt src/animation/sort_test.mbt
git commit -m "feat: implement bubble sort and insertion sort animation"
```

---

### Task 5: Selection Sort + Quick Sort Animation

**Files:**
- Modify: `src/animation/sort.mbt` — replace placeholders
- Modify: `src/animation/sort_test.mbt` — add tests

- [ ] **Step 1: Write failing tests**

Append to `src/animation/sort_test.mbt`:
```moonbit
test "selection sort animation on [3, 1, 2]" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 2],
    algorithm: @types.SortAlgorithm::Selection,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  // Selection sort finds minimum, then swaps
  assert_true(timeline.steps.iter().any(fn(s) { s.description.contains("minimum") || s.description.contains("Minimum") }))
}

test "selection sort empty array" {
  let def : @types.ArrayAnimDef = {
    elements: [],
    algorithm: @types.SortAlgorithm::Selection,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

test "quick sort animation on [3, 1, 4, 1, 5]" {
  let def : @types.ArrayAnimDef = {
    elements: [3, 1, 4, 1, 5],
    algorithm: @types.SortAlgorithm::Quick,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_true(timeline.steps.length() > 0)
  // Quick sort should mention pivot
  assert_true(timeline.steps.iter().any(fn(s) { s.description.contains("pivot") || s.description.contains("Pivot") }))
}

test "quick sort empty array" {
  let def : @types.ArrayAnimDef = {
    elements: [],
    algorithm: @types.SortAlgorithm::Quick,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

test "quick sort single element" {
  let def : @types.ArrayAnimDef = {
    elements: [1],
    algorithm: @types.SortAlgorithm::Quick,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  assert_eq(timeline.steps.length(), 0)
}

test "quick sort already sorted" {
  let def : @types.ArrayAnimDef = {
    elements: [1, 2, 3],
    algorithm: @types.SortAlgorithm::Quick,
  }
  let config = @types.LayoutConfig::default()
  let timeline = @animation.generate_sort_animation(def, config)
  // Should still produce steps (comparisons with pivot)
  assert_true(timeline.steps.length() > 0)
}

test "all sort algorithms produce non-empty timeline for [5, 3, 1]" {
  let algos = [
    @types.SortAlgorithm::Bubble,
    @types.SortAlgorithm::Insertion,
    @types.SortAlgorithm::Selection,
    @types.SortAlgorithm::Quick,
  ]
  let config = @types.LayoutConfig::default()
  for i = 0; i < algos.length(); i = i + 1 {
    let def : @types.ArrayAnimDef = { elements: [5, 3, 1], algorithm: algos[i] }
    let timeline = @animation.generate_sort_animation(def, config)
    assert_true(timeline.steps.length() > 0)
  }
}
```

- [ ] **Step 2: Run tests to verify selection/quick sort tests fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/animation`
Expected: selection/quick sort tests FAIL (empty timeline from placeholders)

- [ ] **Step 3: Implement selection sort**

Replace `generate_selection_sort` in `src/animation/sort.mbt`:
```moonbit
///| Generate selection sort animation.
fn generate_selection_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 { return { steps: [] } }
  let arr = elements.copy()
  let steps : Array[@types.AnimationStep] = []
  for i = 0; i < n - 1; i = i + 1 {
    let mut min_idx = i
    // Highlight current position
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="yellow"),
      ],
      description: "Find minimum from position \{i}",
      duration_ms: 200,
    })
    for j = i + 1; j < n; j = j + 1 {
      // Compare with current minimum
      steps.push({
        actions: [
          @types.AnimationAction::Highlight(node_id=elem_id(j), color="blue"),
          @types.AnimationAction::CompareNodes(a=arr[j].to_string(), b=arr[min_idx].to_string()),
        ],
        description: "Compare \{arr[j]} with current minimum \{arr[min_idx]}",
        duration_ms: 300,
      })
      if arr[j] < arr[min_idx] {
        // New minimum found
        steps.push({
          actions: [
            @types.AnimationAction::Unhighlight(node_id=elem_id(min_idx)),
            @types.AnimationAction::Highlight(node_id=elem_id(j), color="yellow"),
          ],
          description: "New minimum: \{arr[j]}",
          duration_ms: 200,
        })
        min_idx = j
      } else {
        steps.push({
          actions: [
            @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
          ],
          description: "\{arr[j]} >= \{arr[min_idx]}, skip",
          duration_ms: 150,
        })
      }
    }
    // Swap minimum with position i
    if min_idx != i {
      let tmp = arr[i]
      arr[i] = arr[min_idx]
      arr[min_idx] = tmp
      steps.push({
        actions: [
          @types.AnimationAction::SwapNodes(a=elem_id(i), b=elem_id(min_idx)),
          @types.AnimationAction::Unhighlight(node_id=elem_id(min_idx)),
        ],
        description: "Swap \{arr[i]} into position \{i}",
        duration_ms: 400,
      })
    } else {
      steps.push({
        actions: [
          @types.AnimationAction::Unhighlight(node_id=elem_id(i)),
        ],
        description: "\{arr[i]} already in correct position",
        duration_ms: 200,
      })
    }
    // Mark sorted
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "\{arr[i]} is sorted",
      duration_ms: 200,
    })
  }
  // Mark last element
  steps.push({
    actions: [
      @types.AnimationAction::Highlight(node_id=elem_id(n - 1), color="green"),
    ],
    description: "Sort complete",
    duration_ms: 200,
  })
  { steps }
}
```

- [ ] **Step 4: Implement quick sort**

Replace `generate_quick_sort` in `src/animation/sort.mbt`:
```moonbit
///| Generate quick sort animation (Lomuto partition scheme).
fn generate_quick_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 { return { steps: [] } }
  let arr = elements.copy()
  let steps : Array[@types.AnimationStep] = []
  quick_sort_recursive(arr, 0, n - 1, steps)
  // Mark all as sorted
  for i = 0; i < n; i = i + 1 {
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "Sort complete",
      duration_ms: 100,
    })
  }
  { steps }
}

fn quick_sort_recursive(
  arr : Array[Int],
  low : Int,
  high : Int,
  steps : Array[@types.AnimationStep],
) -> Unit {
  if low >= high { return }
  let pivot_idx = partition(arr, low, high, steps)
  quick_sort_recursive(arr, low, pivot_idx - 1, steps)
  quick_sort_recursive(arr, pivot_idx + 1, high, steps)
}

///| Lomuto partition: pivot is arr[high].
fn partition(
  arr : Array[Int],
  low : Int,
  high : Int,
  steps : Array[@types.AnimationStep],
) -> Int {
  let pivot = arr[high]
  // Highlight pivot
  steps.push({
    actions: [
      @types.AnimationAction::Highlight(node_id=elem_id(high), color="yellow"),
      @types.AnimationAction::Annotate(
        text="Pivot: \{pivot}, partition [\{low}..\{high}]", x=0.0, y=0.0,
      ),
    ],
    description: "Pivot: \{pivot} (partition [\{low}..\{high}])",
    duration_ms: 300,
  })
  let mut i = low
  for j = low; j < high; j = j + 1 {
    // Compare with pivot
    steps.push({
      actions: [
        @types.AnimationAction::Highlight(node_id=elem_id(j), color="blue"),
        @types.AnimationAction::CompareNodes(a=arr[j].to_string(), b=pivot.to_string()),
      ],
      description: "Compare \{arr[j]} with pivot \{pivot}",
      duration_ms: 300,
    })
    if arr[j] <= pivot {
      if i != j {
        // Swap arr[i] and arr[j]
        let tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
        steps.push({
          actions: [
            @types.AnimationAction::SwapNodes(a=elem_id(i), b=elem_id(j)),
            @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
          ],
          description: "Swap \{arr[i]} to position \{i}",
          duration_ms: 400,
        })
      } else {
        steps.push({
          actions: [
            @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
          ],
          description: "\{arr[j]} <= pivot, no swap needed",
          duration_ms: 200,
        })
      }
      i = i + 1
    } else {
      steps.push({
        actions: [
          @types.AnimationAction::Unhighlight(node_id=elem_id(j)),
        ],
        description: "\{arr[j]} > pivot, skip",
        duration_ms: 200,
      })
    }
  }
  // Place pivot in final position
  if i != high {
    let tmp = arr[i]
    arr[i] = arr[high]
    arr[high] = tmp
    steps.push({
      actions: [
        @types.AnimationAction::SwapNodes(a=elem_id(i), b=elem_id(high)),
        @types.AnimationAction::Unhighlight(node_id=elem_id(high)),
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "Place pivot \{pivot} at position \{i}",
      duration_ms: 400,
    })
  } else {
    steps.push({
      actions: [
        @types.AnimationAction::Unhighlight(node_id=elem_id(high)),
        @types.AnimationAction::Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "Pivot \{pivot} already in position \{i}",
      duration_ms: 200,
    })
  }
  i
}
```

- [ ] **Step 5: Run tests, moon fmt, commit**

```bash
moon test --target wasm-gc -p paveg/moonmaid/animation
moon fmt
git add src/animation/
git commit -m "feat: implement selection sort and quick sort animation"
```

---

### Task 6: Public API Integration + E2E Tests

**Files:**
- Modify: `src/lib/moon.pkg` — ensure animation is imported
- Modify: `src/lib/moonmaid.mbt` — handle AnimatedArrayDiagram
- Modify: `src/lib/moonmaid_test.mbt` — add e2e tests

- [ ] **Step 1: Write failing e2e tests**

Append to `src/lib/moonmaid_test.mbt`:
```moonbit
test "e2e: array bubble sort animation" {
  let html = @lib.render("array @animate { [3, 1, 4] sort: bubble }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("moonmaid-controls"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("Compare"))
}

test "e2e: array insertion sort animation" {
  let html = @lib.render("array @animate { [3, 1, 2] sort: insertion }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("Insert"))
}

test "e2e: array selection sort animation" {
  let html = @lib.render("array @animate { [5, 3, 1] sort: selection }")
  assert_true(html.contains("moonmaid-animated"))
}

test "e2e: array quick sort animation" {
  let html = @lib.render("array @animate { [3, 1, 4, 1, 5] sort: quick }")
  assert_true(html.contains("moonmaid-animated"))
  assert_true(html.contains("pivot") || html.contains("Pivot"))
}

test "e2e: static array unchanged by animation feature" {
  let svg = @lib.render("array { [1, 2, 3] }")
  assert_true(svg.contains("<svg"))
  assert_true(svg.contains("moonmaid-animated").not())
}

test "e2e: animated empty array sort" {
  let html = @lib.render("array @animate { [] sort: bubble }")
  // Should handle gracefully
  assert_true(html.contains("<svg") || html.contains("moonmaid-animated"))
}

test "e2e: animated single element sort" {
  let html = @lib.render("array @animate { [42] sort: bubble }")
  assert_true(html.contains("<svg") || html.contains("moonmaid-animated"))
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `moon test --target wasm-gc -p paveg/moonmaid/lib`
Expected: FAIL — AnimatedArrayDiagram not handled properly

- [ ] **Step 3: Update render_result in moonmaid.mbt**

Replace the placeholder `AnimatedArrayDiagram` case with:
```moonbit
AnimatedArrayDiagram(def) => {
  let array_def : @types.ArrayDef = { elements: def.elements, highlights: [] }
  let graph = @grid.layout(array_def, config)
  let timeline = @animation.generate_sort_animation(def, config)
  @renderer.render_animated(graph, timeline)
}
```

- [ ] **Step 4: Run full test suite, moon fmt, commit**

```bash
moon test --target wasm-gc
moon fmt
git add src/lib/
git commit -m "feat: integrate array sort animation into public API"
```

---

## Summary

| Task | Component | New Tests |
|---|---|---|
| 1 | Types: SortAlgorithm, ArrayAnimDef | 2 |
| 2 | Lexer: sort algorithm tokens | 2 |
| 3 | Parser: array @animate sort | 6 |
| 4 | Bubble sort + Insertion sort animation | 6 |
| 5 | Selection sort + Quick sort animation | 7 |
| 6 | Public API + E2E tests | 7 |

**Total: 6 tasks, ~30 new tests, ~6 commits**
