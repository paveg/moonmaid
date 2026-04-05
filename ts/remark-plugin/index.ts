import type { Plugin } from 'unified'
import type { Root, Code } from 'mdast'
import { visit } from 'unist-util-visit'
import { loadMoonmaid, type MoonmaidInstance } from '../wasm-bridge/index.js'

export interface RemarkMoonmaidOptions {
  maxNodes?: number
  maxArraySize?: number
  wasmPath?: string
}

const remarkMoonmaid: Plugin<[RemarkMoonmaidOptions?], Root> = (options = {}) => {
  // Cache the instance promise per plugin invocation so that multiple
  // documents processed by the same plugin share one WASM load.
  let instancePromise: Promise<MoonmaidInstance> | null = null

  return async (tree: Root) => {
    const codeBlocks: Code[] = []
    visit(tree, 'code', (node: Code) => {
      if (node.lang === 'moonmaid') codeBlocks.push(node)
    })
    if (codeBlocks.length === 0) return

    if (!instancePromise) instancePromise = loadMoonmaid(options.wasmPath)
    const moonmaid = await instancePromise

    for (const node of codeBlocks) {
      const svg = moonmaid.render(node.value)
      const htmlNode = node as unknown as { type: string; value: string }
      htmlNode.type = 'html'
      htmlNode.value = `<figure class="moonmaid" style="margin: 16px 0">${svg}</figure>`
    }
  }
}

export default remarkMoonmaid
