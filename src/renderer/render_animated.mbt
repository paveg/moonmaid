///|
/// Render a tree diagram with animation playback controls.
///
/// Produces an HTML fragment containing:
/// - A styled container with border
/// - An SVG with data-node-id / data-edge-id attributes for JS targeting
/// - Playback controls (prev, play/pause, next, progress, speed)
/// - Step description display
/// - Inline JS that reads the timeline JSON and drives the animation
pub fn render_animated(
  graph : @types.PositionedGraph,
  timeline : @types.AnimationTimeline,
) -> String {
  let buf = StringBuilder::new()
  let bounds = graph.bounds
  let svg_width = bounds.width
  let svg_height = bounds.height
  let timeline_json = @animation.timeline_to_json(timeline)
  let step_count = timeline.steps.length()

  // Outer container
  buf.write_string("<div class=\"moonmaid-animated\">")

  // Style block
  buf.write_string("<style>")
  buf.write_string(
    (
      #| .moonmaid-animated { border: 1px solid #d1d9e0; border-radius: 8px; overflow: hidden }
    ),
  )
  buf.write_string(
    (
      #| .mm-btn { background: none; border: 1px solid #d1d9e0; border-radius: 4px; padding: 2px 8px; cursor: pointer; font-size: 14px; color: #656d76 }
    ),
  )
  buf.write_string(
    (
      #| .mm-btn:hover { background: #f6f8fa; color: #1f2328 }
    ),
  )
  buf.write_string(
    (
      #| .moonmaid-controls { display: flex; align-items: center; gap: 6px; padding: 8px 12px; border-top: 1px solid #d1d9e0; background: #f6f8fa }
    ),
  )
  buf.write_string(
    (
      #| .moonmaid-description { padding: 8px 12px; font-size: 13px; color: #1f2328; min-height: 24px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif }
    ),
  )
  buf.write_string("</style>")

  // SVG with data-node-id and data-edge-id attributes
  buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"")
  buf.write_string(fmt_double(svg_width))
  buf.write_string("\" height=\"")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\" viewBox=\"0 0 ")
  buf.write_string(fmt_double(svg_width))
  buf.write_string(" ")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\">")

  // Background rect
  buf.write_string("<rect x=\"0\" y=\"0\" width=\"")
  buf.write_string(fmt_double(svg_width))
  buf.write_string("\" height=\"")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\" rx=\"0\" fill=\"")
  buf.write_string(escape_xml(bg))
  buf.write_string("\" stroke=\"none\" stroke-width=\"0\"/>")

  // Arrow marker definition
  buf.write_string(
    "<defs><marker id=\"arrow\" markerWidth=\"10\" markerHeight=\"7\" refX=\"10\" refY=\"3.5\" orient=\"auto\"><path d=\"M 0 0 L 10 3.5 L 0 7 z\" fill=\"",
  )
  buf.write_string(escape_xml(edge_color))
  buf.write_string("\" stroke=\"none\"/></marker></defs>")

  // Edges with data-edge-id
  for i = 0; i < graph.edges.length(); i = i + 1 {
    let edge = graph.edges[i]
    if edge.points.length() >= 2 {
      let edge_id = escape_xml(edge.from_id) + "-" + escape_xml(edge.to_id)
      buf.write_string("<g data-edge-id=\"")
      buf.write_string(edge_id)
      buf.write_string("\"><polyline points=\"")
      buf.write_string(fmt_points(edge.points))
      buf.write_string("\" stroke=\"")
      buf.write_string(escape_xml(edge_color))
      buf.write_string(
        "\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arrow)\"/></g>",
      )
    }
  }

  // Node groups with data-node-id
  for i = 0; i < graph.nodes.length(); i = i + 1 {
    let node = graph.nodes[i]
    buf.write_string("<g data-node-id=\"")
    buf.write_string(escape_xml(node.id))
    buf.write_string("\">")
    buf.write_string("<rect x=\"")
    buf.write_string(fmt_double(node.x))
    buf.write_string("\" y=\"")
    buf.write_string(fmt_double(node.y))
    buf.write_string("\" width=\"")
    buf.write_string(fmt_double(node.width))
    buf.write_string("\" height=\"")
    buf.write_string(fmt_double(node.height))
    buf.write_string("\" rx=\"6\" fill=\"")
    buf.write_string(escape_xml(node_fill))
    buf.write_string("\" stroke=\"")
    buf.write_string(escape_xml(node_stroke))
    buf.write_string("\" stroke-width=\"1.5\"/>")
    let cx = node.x + node.width / 2.0
    let cy = node.y + node.height / 2.0
    buf.write_string("<text x=\"")
    buf.write_string(fmt_double(cx))
    buf.write_string("\" y=\"")
    buf.write_string(fmt_double(cy))
    buf.write_string("\" font-size=\"13\" fill=\"")
    buf.write_string(escape_xml(text_color))
    buf.write_string(
      "\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"",
    )
    buf.write_string(escape_xml(font_family))
    buf.write_string("\">")
    buf.write_string(escape_xml(node.label))
    buf.write_string("</text>")
    buf.write_string("</g>")
  }

  buf.write_string("</svg>")

  // Controls
  buf.write_string("<div class=\"moonmaid-controls\">")
  buf.write_string(
    "<button class=\"mm-btn\" data-action=\"prev\" title=\"Previous\">&laquo;</button>",
  )
  buf.write_string(
    "<button class=\"mm-btn\" data-action=\"play\" title=\"Play\">&#9654;</button>",
  )
  buf.write_string(
    "<button class=\"mm-btn\" data-action=\"next\" title=\"Next\">&raquo;</button>",
  )
  buf.write_string("<input type=\"range\" min=\"0\" max=\"")
  buf.write_string(
    (if step_count > 0 { step_count - 1 } else { 0 }).to_string(),
  )
  buf.write_string("\" value=\"0\" data-action=\"progress\" style=\"flex:1\"/>")
  buf.write_string(
    "<select data-action=\"speed\"><option value=\"0.5\">0.5x</option><option value=\"1\" selected>1x</option><option value=\"2\">2x</option></select>",
  )
  buf.write_string("</div>")

  // Description area
  buf.write_string("<div class=\"moonmaid-description\"></div>")

  // Inline playback JS (uses textContent for XSS safety)
  buf.write_string("<script>(function(){")
  buf.write_string("var timeline=")
  buf.write_string(timeline_json)
  buf.write_string(";")
  buf.write_string(
    (
      #| var root=document.currentScript.parentElement;
    ),
  )
  buf.write_string(
    (
      #| var desc=root.querySelector('.moonmaid-description');
    ),
  )
  buf.write_string(
    (
      #| var progress=root.querySelector('[data-action=progress]');
    ),
  )
  buf.write_string(
    (
      #| var idx=-1,timer=null,speed=1;
    ),
  )
  buf.write_string(
    (
      #| function goTo(n){idx=Math.max(-1,Math.min(n,timeline.steps.length-1));progress.value=Math.max(0,idx);desc.textContent=idx>=0?timeline.steps[idx].description:'';}
    ),
  )
  buf.write_string(
    (
      #| function tick(){if(idx<timeline.steps.length-1){goTo(idx+1);}else{pause();}}
    ),
  )
  buf.write_string(
    (
      #| function play(){pause();var ms=idx>=0&&idx<timeline.steps.length?timeline.steps[idx].duration_ms:400;timer=setInterval(tick,ms/speed);}
    ),
  )
  buf.write_string(
    (
      #| function pause(){if(timer){clearInterval(timer);timer=null;}}
    ),
  )
  buf.write_string(
    (
      #| root.querySelector('[data-action=prev]').addEventListener('click',function(){pause();goTo(idx-1);});
    ),
  )
  buf.write_string(
    (
      #| root.querySelector('[data-action=play]').addEventListener('click',function(){if(timer){pause();}else{play();}});
    ),
  )
  buf.write_string(
    (
      #| root.querySelector('[data-action=next]').addEventListener('click',function(){pause();goTo(idx+1);});
    ),
  )
  buf.write_string(
    (
      #| progress.addEventListener('input',function(){pause();goTo(parseInt(progress.value));});
    ),
  )
  buf.write_string(
    (
      #| root.querySelector('[data-action=speed]').addEventListener('change',function(e){speed=parseFloat(e.target.value);if(timer){play();}});
    ),
  )
  buf.write_string("})()</script>")

  buf.write_string("</div>")
  buf.to_string()
}
