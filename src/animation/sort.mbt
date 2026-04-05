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
      // Highlight pair for comparison
      steps.push({
        actions: [
          Highlight(node_id=id_j, color="blue"),
          Highlight(node_id=id_j1, color="blue"),
          CompareNodes(a=id_j, b=id_j1),
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
          actions: [SwapNodes(a=id_j, b=id_j1)],
          description: "Swap \{arr[j + 1]} and \{arr[j]}",
          duration_ms: 400,
        })
        swapped = true
      }
      // Unhighlight pair
      steps.push({
        actions: [Unhighlight(node_id=id_j), Unhighlight(node_id=id_j1)],
        description: "Unhighlight",
        duration_ms: 100,
      })
    }
    // Mark sorted position
    let sorted_idx = n - 1 - i
    steps.push({
      actions: [Highlight(node_id=elem_id(sorted_idx), color="green")],
      description: "\{arr[sorted_idx]} is in sorted position",
      duration_ms: 200,
    })
    if not(swapped) {
      // Already sorted, mark remaining as green
      for k = 0; k < sorted_idx; k = k + 1 {
        steps.push({
          actions: [Highlight(node_id=elem_id(k), color="green")],
          description: "\{arr[k]} is in sorted position",
          duration_ms: 100,
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
        duration_ms: 200,
      })
    }
  }
  { steps, }
}

///|
/// Generate insertion sort animation steps.
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
    duration_ms: 200,
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
      // Compare with left neighbor
      steps.push({
        actions: [
          Highlight(node_id=id_j1, color="blue"),
          CompareNodes(a=id_j, b=id_j1),
        ],
        description: "Compare \{key} with \{arr[j - 1]}",
        duration_ms: 300,
      })
      // Shift right via swap
      let tmp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = tmp
      steps.push({
        actions: [SwapNodes(a=id_j, b=id_j1), Unhighlight(node_id=id_j)],
        description: "Shift \{arr[j]} right",
        duration_ms: 400,
      })
      j = j - 1
    }
    // Mark placed position as sorted
    steps.push({
      actions: [Highlight(node_id=elem_id(j), color="green")],
      description: "\{key} placed at position \{j}",
      duration_ms: 200,
    })
  }
  { steps, }
}

///|
/// Generate selection sort animation steps.
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
      duration_ms: 200,
    })
    for j = i + 1; j < n; j = j + 1 {
      let id_j = elem_id(j)
      // Highlight candidate
      steps.push({
        actions: [
          Highlight(node_id=id_j, color="blue"),
          CompareNodes(a=id_j, b=elem_id(min_idx)),
        ],
        description: "Compare \{arr[j]} with minimum \{arr[min_idx]}",
        duration_ms: 300,
      })
      if arr[j] < arr[min_idx] {
        // New minimum found
        steps.push({
          actions: [
            Unhighlight(node_id=elem_id(min_idx)),
            Highlight(node_id=id_j, color="yellow"),
          ],
          description: "New minimum: \{arr[j]}",
          duration_ms: 200,
        })
        min_idx = j
      } else {
        steps.push({
          actions: [Unhighlight(node_id=id_j)],
          description: "\{arr[j]} is not smaller",
          duration_ms: 100,
        })
      }
    }
    // Swap minimum into position
    if min_idx != i {
      let tmp = arr[i]
      arr[i] = arr[min_idx]
      arr[min_idx] = tmp
      steps.push({
        actions: [
          SwapNodes(a=elem_id(i), b=elem_id(min_idx)),
          Unhighlight(node_id=elem_id(min_idx)),
        ],
        description: "Swap minimum \{arr[i]} into position \{i}",
        duration_ms: 400,
      })
    } else {
      steps.push({
        actions: [Unhighlight(node_id=elem_id(i))],
        description: "\{arr[i]} already in position",
        duration_ms: 100,
      })
    }
    // Mark sorted
    steps.push({
      actions: [Highlight(node_id=elem_id(i), color="green")],
      description: "\{arr[i]} is in sorted position",
      duration_ms: 200,
    })
  }
  // Mark last element as sorted
  steps.push({
    actions: [Highlight(node_id=elem_id(n - 1), color="green")],
    description: "\{arr[n - 1]} is in sorted position",
    duration_ms: 200,
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
        duration_ms: 200,
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
    // Compare element with pivot
    steps.push({
      actions: [
        Highlight(node_id=id_j, color="blue"),
        CompareNodes(a=id_j, b=pivot_id),
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
          actions: [SwapNodes(a=elem_id(i), b=id_j)],
          description: "Swap \{arr[i]} to left partition",
          duration_ms: 400,
        })
      }
      steps.push({
        actions: [Unhighlight(node_id=elem_id(i))],
        description: "Advance partition index",
        duration_ms: 100,
      })
      i = i + 1
    } else {
      steps.push({
        actions: [Unhighlight(node_id=id_j)],
        description: "\{arr[j]} stays in right partition",
        duration_ms: 100,
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
      ],
      description: "Place pivot \{arr[i]} at position \{i}",
      duration_ms: 400,
    })
  } else {
    steps.push({
      actions: [Unhighlight(node_id=pivot_id)],
      description: "Pivot already in position",
      duration_ms: 100,
    })
  }
  // Mark pivot position as sorted
  steps.push({
    actions: [Highlight(node_id=elem_id(i), color="green")],
    description: "\{arr[i]} is in sorted position",
    duration_ms: 200,
  })
  // Recurse on sub-arrays
  if i > low {
    quick_sort_recurse(arr, low, i - 1, steps)
  }
  if i < high {
    quick_sort_recurse(arr, i + 1, high, steps)
  }
}
