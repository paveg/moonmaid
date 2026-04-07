///|
/// Generate an animation timeline for array sort algorithms.
/// Dispatches to the appropriate sort algorithm based on `def.algorithm`.
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

///|
/// Node ID for array element at index i.
fn elem_id(i : Int) -> String {
  "elem_\{i}"
}

///|
/// Generate bubble sort animation steps.
/// Each comparison is a single merged step (highlight, compare, swap/no-swap, unhighlight).
fn generate_bubble_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 {
    return { steps: [] }
  }
  let arr = Array::copy(elements)
  let steps : Array[@types.AnimationStep] = []
  for i = 0; i < n - 1; i = i + 1 {
    let mut swapped = false
    for j = 0; j < n - 1 - i; j = j + 1 {
      let id_j = elem_id(j)
      let id_j1 = elem_id(j + 1)
      let val_j = arr[j]
      let val_j1 = arr[j + 1]
      if arr[j] > arr[j + 1] {
        // Swap needed
        let tmp = arr[j]
        arr[j] = arr[j + 1]
        arr[j + 1] = tmp
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            Highlight(node_id=id_j1, color="blue"),
            CompareNodes(a=id_j, b=id_j1),
            SwapNodes(a=id_j, b=id_j1),
            Unhighlight(node_id=id_j),
            Unhighlight(node_id=id_j1),
          ],
          description: "Compare \{val_j} and \{val_j1} \u{2192} Swap",
          duration_ms: 500,
        })
        swapped = true
      } else {
        // No swap needed
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            Highlight(node_id=id_j1, color="blue"),
            CompareNodes(a=id_j, b=id_j1),
            Unhighlight(node_id=id_j),
            Unhighlight(node_id=id_j1),
          ],
          description: "Compare \{val_j} and \{val_j1} \u{2192} No swap",
          duration_ms: 500,
        })
      }
    }
    // Mark sorted position
    let sorted_idx = n - 1 - i
    steps.push({
      actions: [Highlight(node_id=elem_id(sorted_idx), color="green")],
      description: "\{arr[sorted_idx]} is in sorted position",
      duration_ms: 300,
    })
    if not(swapped) {
      // Already sorted, mark remaining as green
      for k = 0; k < sorted_idx; k = k + 1 {
        steps.push({
          actions: [Highlight(node_id=elem_id(k), color="green")],
          description: "\{arr[k]} is in sorted position",
          duration_ms: 300,
        })
      }
      break
    }
  }
  // Mark first element as sorted if we completed all passes
  if steps.length() > 0 {
    let last = steps[steps.length() - 1]
    let already_marked = match last.actions[0] {
      Highlight(node_id=id, color="green") => id == elem_id(0)
      _ => false
    }
    if not(already_marked) {
      steps.push({
        actions: [Highlight(node_id=elem_id(0), color="green")],
        description: "\{arr[0]} is in sorted position",
        duration_ms: 300,
      })
    }
  }
  { steps, }
}

///|
/// Generate insertion sort animation steps.
/// Each compare-and-shift is a single merged step.
fn generate_insertion_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 {
    return { steps: [] }
  }
  let arr = Array::copy(elements)
  let steps : Array[@types.AnimationStep] = []
  // Mark first element as sorted
  steps.push({
    actions: [Highlight(node_id=elem_id(0), color="green")],
    description: "\{arr[0]} is initially sorted",
    duration_ms: 300,
  })
  for i = 1; i < n; i = i + 1 {
    let key = arr[i]
    // Highlight key element
    steps.push({
      actions: [Highlight(node_id=elem_id(i), color="yellow")],
      description: "Insert key \{key}",
      duration_ms: 300,
    })
    let mut j = i
    while j > 0 && arr[j - 1] > key {
      let id_j = elem_id(j)
      let id_j1 = elem_id(j - 1)
      let neighbor = arr[j - 1]
      // Compare and shift in one step
      let tmp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = tmp
      steps.push({
        actions: [
          Highlight(node_id=id_j1, color="blue"),
          CompareNodes(a=id_j, b=id_j1),
          SwapNodes(a=id_j, b=id_j1),
          Unhighlight(node_id=id_j),
          Unhighlight(node_id=id_j1),
        ],
        description: "Compare \{key} with \{neighbor} \u{2192} Shift right",
        duration_ms: 500,
      })
      j = j - 1
    }
    // Mark placed position as sorted
    steps.push({
      actions: [Highlight(node_id=elem_id(j), color="green")],
      description: "\{key} placed at position \{j}",
      duration_ms: 300,
    })
  }
  { steps, }
}

///|
/// Generate selection sort animation steps.
/// Each comparison is merged into a single step.
fn generate_selection_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 {
    return { steps: [] }
  }
  let arr = Array::copy(elements)
  let steps : Array[@types.AnimationStep] = []
  for i = 0; i < n - 1; i = i + 1 {
    let mut min_idx = i
    // Highlight current minimum
    steps.push({
      actions: [Highlight(node_id=elem_id(i), color="yellow")],
      description: "Find minimum starting at index \{i}",
      duration_ms: 300,
    })
    for j = i + 1; j < n; j = j + 1 {
      let id_j = elem_id(j)
      if arr[j] < arr[min_idx] {
        // New minimum found: compare, unhighlight old min, highlight new min
        let old_min_id = elem_id(min_idx)
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            CompareNodes(a=id_j, b=old_min_id),
            Unhighlight(node_id=old_min_id),
            Highlight(node_id=id_j, color="yellow"),
          ],
          description: "Compare \{arr[j]} with minimum \{arr[min_idx]} \u{2192} New minimum: \{arr[j]}",
          duration_ms: 500,
        })
        min_idx = j
      } else {
        // Not smaller: compare and unhighlight
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            CompareNodes(a=id_j, b=elem_id(min_idx)),
            Unhighlight(node_id=id_j),
          ],
          description: "Compare \{arr[j]} with minimum \{arr[min_idx]} \u{2192} Not smaller",
          duration_ms: 500,
        })
      }
    }
    // Swap minimum into position (or note already in place)
    if min_idx != i {
      let tmp = arr[i]
      arr[i] = arr[min_idx]
      arr[min_idx] = tmp
      steps.push({
        actions: [
          SwapNodes(a=elem_id(i), b=elem_id(min_idx)),
          Unhighlight(node_id=elem_id(min_idx)),
          Highlight(node_id=elem_id(i), color="green"),
        ],
        description: "Swap minimum \{arr[i]} into position \{i}",
        duration_ms: 500,
      })
    } else {
      steps.push({
        actions: [
          Unhighlight(node_id=elem_id(i)),
          Highlight(node_id=elem_id(i), color="green"),
        ],
        description: "\{arr[i]} already in position",
        duration_ms: 300,
      })
    }
  }
  // Mark last element as sorted
  steps.push({
    actions: [Highlight(node_id=elem_id(n - 1), color="green")],
    description: "\{arr[n - 1]} is in sorted position",
    duration_ms: 300,
  })
  { steps, }
}

///|
/// Generate quick sort animation steps using Lomuto partition.
fn generate_quick_sort(elements : Array[Int]) -> @types.AnimationTimeline {
  let n = elements.length()
  if n <= 1 {
    return { steps: [] }
  }
  let arr = Array::copy(elements)
  let steps : Array[@types.AnimationStep] = []
  quick_sort_recurse(arr, 0, n - 1, steps)
  { steps, }
}

///|
/// Recursive quick sort with Lomuto partition scheme.
/// Each comparison is merged into a single step.
fn quick_sort_recurse(
  arr : Array[Int],
  low : Int,
  high : Int,
  steps : Array[@types.AnimationStep],
) -> Unit {
  if low >= high {
    if low == high {
      steps.push({
        actions: [Highlight(node_id=elem_id(low), color="green")],
        description: "\{arr[low]} is in sorted position",
        duration_ms: 300,
      })
    }
    return
  }
  let pivot = arr[high]
  let pivot_id = elem_id(high)
  // Highlight pivot
  steps.push({
    actions: [
      Highlight(node_id=pivot_id, color="yellow"),
      Annotate(text="Pivot: \{pivot}", x=0.0, y=0.0),
    ],
    description: "Select pivot \{pivot} at index \{high}",
    duration_ms: 300,
  })
  let mut i = low
  for j = low; j < high; j = j + 1 {
    let id_j = elem_id(j)
    let val_j = arr[j]
    if arr[j] <= pivot {
      if i != j {
        // Compare, swap to left partition, unhighlight — one step
        let tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            CompareNodes(a=id_j, b=pivot_id),
            SwapNodes(a=elem_id(i), b=id_j),
            Unhighlight(node_id=elem_id(i)),
          ],
          description: "Compare \{val_j} \u{2264} pivot \{pivot} \u{2192} Swap to left",
          duration_ms: 500,
        })
      } else {
        // No swap needed, just compare and advance
        steps.push({
          actions: [
            Highlight(node_id=id_j, color="blue"),
            CompareNodes(a=id_j, b=pivot_id),
            Unhighlight(node_id=id_j),
          ],
          description: "Compare \{val_j} \u{2264} pivot \{pivot} \u{2192} Left partition",
          duration_ms: 500,
        })
      }
      i = i + 1
    } else {
      // Greater than pivot — compare and unhighlight
      steps.push({
        actions: [
          Highlight(node_id=id_j, color="blue"),
          CompareNodes(a=id_j, b=pivot_id),
          Unhighlight(node_id=id_j),
        ],
        description: "Compare \{val_j} > pivot \{pivot} \u{2192} Right partition",
        duration_ms: 500,
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
        SwapNodes(a=elem_id(i), b=pivot_id),
        Unhighlight(node_id=pivot_id),
        Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "Place pivot \{arr[i]} at position \{i}",
      duration_ms: 500,
    })
  } else {
    steps.push({
      actions: [
        Unhighlight(node_id=pivot_id),
        Highlight(node_id=elem_id(i), color="green"),
      ],
      description: "Pivot \{arr[i]} already in position \{i}",
      duration_ms: 300,
    })
  }
  // Recurse on sub-arrays
  if i > low {
    quick_sort_recurse(arr, low, i - 1, steps)
  }
  if i < high {
    quick_sort_recurse(arr, i + 1, high, steps)
  }
}
