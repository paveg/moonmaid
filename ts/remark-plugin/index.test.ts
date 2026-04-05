import { describe, it, expect, vi, beforeEach } from 'vitest'
import { unified } from 'unified'
import remarkParse from 'remark-parse'
import type { Root, Code, Html, RootContent } from 'mdast'
import { visit } from 'unist-util-visit'

// Mock the WASM bridge so tests never load actual WASM
vi.mock('../wasm-bridge/index.js', () => {
  return {
    loadMoonmaid: vi.fn().mockResolvedValue({
      render: (input: string) => `<svg data-input="${input}"/>`,
    }),
    clearCache: vi.fn(),
  }
})

import remarkMoonmaid from './index.js'
import { loadMoonmaid } from '../wasm-bridge/index.js'

beforeEach(() => {
  vi.mocked(loadMoonmaid).mockResolvedValue({
    render: (input: string) => `<svg data-input="${input}"/>`,
  })
  vi.mocked(loadMoonmaid).mockClear()
})

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

async function processMarkdown(markdown: string): Promise<Root> {
  const processor = unified()
    .use(remarkParse)
    .use(remarkMoonmaid)

  const tree = processor.parse(markdown)
  return (await processor.run(tree)) as Root
}

/**
 * Collect nodes by type using direct tree traversal rather than unist-util-visit,
 * to avoid potential issues with how visit handles mutated node types in test envs.
 */
function childrenOfType<T extends RootContent>(tree: Root, type: string): T[] {
  return tree.children.filter((c) => c.type === type) as T[]
}

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

describe('remarkMoonmaid – code block detection', () => {
  it('identifies moonmaid code blocks and replaces them with html nodes', async () => {
    const md = '```moonmaid\narray [1, 2, 3]\n```'
    const tree = await processMarkdown(md)

    expect(childrenOfType<Html>(tree, 'html')).toHaveLength(1)
    expect(childrenOfType<Code>(tree, 'code')).toHaveLength(0)
  })

  it('wraps the rendered SVG in a figure element with the correct class', async () => {
    const md = '```moonmaid\narray [1, 2, 3]\n```'
    const tree = await processMarkdown(md)

    const [htmlNode] = childrenOfType<Html>(tree, 'html')
    expect(htmlNode.value).toMatch(/^<figure class="moonmaid"/)
    expect(htmlNode.value).toContain('<svg')
    expect(htmlNode.value).toMatch(/<\/figure>$/)
  })

  it('passes the raw code block content to render', async () => {
    const diagram = 'tree bst [5, 3, 7]'
    const md = `\`\`\`moonmaid\n${diagram}\n\`\`\``
    const tree = await processMarkdown(md)

    const [htmlNode] = childrenOfType<Html>(tree, 'html')
    // Our mock encodes the input into the svg attribute for inspection
    expect(htmlNode.value).toContain(diagram)
  })

  it('ignores non-moonmaid code blocks', async () => {
    const md = '```javascript\nconsole.log("hello")\n```'
    const tree = await processMarkdown(md)

    const codeNodes = childrenOfType<Code>(tree, 'code')
    expect(codeNodes).toHaveLength(1)
    expect(codeNodes[0].lang).toBe('javascript')
    expect(childrenOfType<Html>(tree, 'html')).toHaveLength(0)
  })

  it('handles a document with both moonmaid and non-moonmaid blocks', async () => {
    const md = [
      '```moonmaid',
      'array [1, 2]',
      '```',
      '',
      '```python',
      'print("hi")',
      '```',
    ].join('\n')

    const tree = await processMarkdown(md)

    const htmlNodes = childrenOfType<Html>(tree, 'html')
    const codeNodes = childrenOfType<Code>(tree, 'code')

    // moonmaid block → html, python block → code (unchanged)
    expect(htmlNodes).toHaveLength(1)
    expect(htmlNodes[0].value).toContain('<figure')
    expect(codeNodes).toHaveLength(1)
    expect(codeNodes[0].lang).toBe('python')
  })

  it('does not load WASM when there are no moonmaid code blocks', async () => {
    const md = '```javascript\nconsole.log("hello")\n```'
    await processMarkdown(md)

    expect(loadMoonmaid).not.toHaveBeenCalled()
  })

  it('loads WASM exactly once for multiple moonmaid blocks', async () => {
    const md = [
      '```moonmaid',
      'array [1]',
      '```',
      '',
      '```moonmaid',
      'array [2]',
      '```',
    ].join('\n')

    await processMarkdown(md)

    // loadMoonmaid is called once per plugin invocation (instance is cached inside plugin)
    expect(loadMoonmaid).toHaveBeenCalledTimes(1)
  })

  it('applies the style attribute to the figure wrapper', async () => {
    const md = '```moonmaid\narray [1]\n```'
    const tree = await processMarkdown(md)

    const [htmlNode] = childrenOfType<Html>(tree, 'html')
    expect(htmlNode.value).toContain('style="margin: 16px 0"')
  })

  it('visit traversal correctly skips the mutated html node (smoke test)', async () => {
    // Verify via visit that html nodes appear once and code nodes are gone
    // after processing a single moonmaid block
    const md = '```moonmaid\narray [1]\n```'
    const tree = await processMarkdown(md)

    const htmlViaVisit: Html[] = []
    const codeViaVisit: Code[] = []
    visit(tree, 'html', (n: Html) => htmlViaVisit.push(n))
    visit(tree, 'code', (n: Code) => codeViaVisit.push(n))

    expect(htmlViaVisit).toHaveLength(1)
    expect(codeViaVisit).toHaveLength(0)
  })
})
