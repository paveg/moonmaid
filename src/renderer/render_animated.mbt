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
  buf.write_string(
    "<style>.moonmaid-animated{border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;font-family:Inter,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif}.moonmaid-animated svg{display:block;width:100%;height:auto}.moonmaid-controls{display:flex;align-items:center;gap:8px;padding:10px 16px;border-top:1px solid #e2e8f0}.mm-btn{background:none;border:1px solid #e2e8f0;border-radius:8px;padding:6px 12px;cursor:pointer;font-size:14px;color:#64748b;line-height:1}.mm-btn:hover{background:#f1f5f9;color:#334155}.mm-play{background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:6px 14px;cursor:pointer;font-size:14px;line-height:1}.mm-play:hover{background:#2563eb}.mm-step{font-size:12px;color:#94a3b8;white-space:nowrap}.mm-progress{flex:1;height:4px;-webkit-appearance:none;appearance:none;background:#e2e8f0;border-radius:2px;outline:none}.mm-progress::-webkit-slider-thumb{-webkit-appearance:none;width:14px;height:14px;border-radius:50%;background:#3b82f6;cursor:pointer}.mm-progress::-moz-range-thumb{width:14px;height:14px;border-radius:50%;background:#3b82f6;cursor:pointer;border:none}.mm-speed{border:1px solid #e2e8f0;border-radius:6px;padding:4px 8px;font-size:12px;color:#64748b;background:transparent;cursor:pointer}.moonmaid-description{padding:8px 16px;font-size:13px;color:#64748b;min-height:24px}</style>",
  )

  // SVG with data-node-id and data-edge-id attributes
  buf.write_string("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"")
  buf.write_string(fmt_double(svg_width))
  buf.write_string("\" height=\"")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\" viewBox=\"0 0 ")
  buf.write_string(fmt_double(svg_width))
  buf.write_string(" ")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\" style=\"max-width:100%;height:auto\">")

  // Shadow filter defs
  buf.write_string("<defs>")
  buf.write_string(shadow_filter_def)

  // Arrow marker definition
  buf.write_string(
    "<marker id=\"arrow\" markerWidth=\"10\" markerHeight=\"7\" refX=\"10\" refY=\"3.5\" orient=\"auto\"><path d=\"M 0 0 L 10 3.5 L 0 7 z\" fill=\"",
  )
  buf.write_string(escape_xml(edge_color))
  buf.write_string("\" stroke=\"none\"/></marker></defs>")

  // Background rect
  buf.write_string("<rect x=\"0\" y=\"0\" width=\"")
  buf.write_string(fmt_double(svg_width))
  buf.write_string("\" height=\"")
  buf.write_string(fmt_double(svg_height))
  buf.write_string("\" rx=\"0\" fill=\"")
  buf.write_string(escape_xml(bg))
  buf.write_string("\" stroke=\"none\" stroke-width=\"0\"/>")

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
    buf.write_string("\" rx=\"14\" fill=\"")
    buf.write_string(escape_xml(node_fill))
    buf.write_string("\" stroke=\"")
    buf.write_string(escape_xml(node_stroke))
    buf.write_string("\" stroke-width=\"1.5\" filter=\"url(#")
    buf.write_string(shadow_filter_id)
    buf.write_string(")\"/>")
    let cx = node.x + node.width / 2.0
    let cy = node.y + node.height / 2.0
    buf.write_string("<text x=\"")
    buf.write_string(fmt_double(cx))
    buf.write_string("\" y=\"")
    buf.write_string(fmt_double(cy))
    buf.write_string("\" font-size=\"14\" fill=\"")
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
    "<button class=\"mm-play\" data-action=\"play\" title=\"Play\">&#9654;</button>",
  )
  buf.write_string(
    "<button class=\"mm-btn\" data-action=\"next\" title=\"Next\">&raquo;</button>",
  )
  buf.write_string("<input type=\"range\" min=\"0\" max=\"")
  buf.write_string(
    (if step_count > 0 { step_count - 1 } else { 0 }).to_string(),
  )
  buf.write_string(
    "\" value=\"0\" data-action=\"progress\" class=\"mm-progress\"/>",
  )
  buf.write_string(
    "<span class=\"mm-step\" data-action=\"step-counter\"></span>",
  )
  buf.write_string(
    "<select class=\"mm-speed\" data-action=\"speed\"><option value=\"0.5\">0.5x</option><option value=\"1\" selected>1x</option><option value=\"2\">2x</option></select>",
  )
  buf.write_string("</div>")

  // Description area
  buf.write_string("<div class=\"moonmaid-description\"></div>")

  // Inline playback JS (uses textContent for XSS safety)
  buf.write_string("<script>(function(){var timeline=")
  buf.write_string(timeline_json)
  buf.write_string(
    (
      #|;var root=document.currentScript.parentElement;var svg=root.querySelector('svg');var desc=root.querySelector('.moonmaid-description');var progress=root.querySelector('[data-action=progress]');var counter=root.querySelector('[data-action=step-counter]');var playBtn=root.querySelector('[data-action=play]');var idx=-1,timer=null,speed=1;var colors={blue:{fill:'#dbeafe',stroke:'#93c5fd'},green:{fill:'#dcfce7',stroke:'#86efac'},yellow:{fill:'#fef9c3',stroke:'#fde047'},red:{fill:'#fee2e2',stroke:'#fca5a5'},purple:{fill:'#ede9fe',stroke:'#c4b5fd'}};var defaultStyle={fill:'#ffffff',stroke:'#e2e8f0'};function findNode(id){var nodes=svg.querySelectorAll('[data-node-id]');for(var i=0;i<nodes.length;i++){if(nodes[i].getAttribute('data-node-id')===id)return nodes[i];}return null;}function setNodeStyle(id,style){var g=findNode(id);if(!g)return;var rect=g.querySelector('rect');if(rect){rect.setAttribute('fill',style.fill);rect.setAttribute('stroke',style.stroke);}}function resetAll(){svg.querySelectorAll('[data-node-id] rect').forEach(function(rect){rect.setAttribute('fill',defaultStyle.fill);rect.setAttribute('stroke',defaultStyle.stroke);});}function applyStep(stepIdx){if(stepIdx<0||stepIdx>=timeline.steps.length)return;var step=timeline.steps[stepIdx];if(!step.actions)return;for(var i=0;i<step.actions.length;i++){var a=step.actions[i];switch(a.type){case'Highlight':var c=colors[a.color]||defaultStyle;setNodeStyle(a.node_id,c);break;case'Unhighlight':setNodeStyle(a.node_id,defaultStyle);break;case'SwapNodes':var ga=findNode(a.a);var gb=findNode(a.b);if(ga&&gb){var ta=ga.querySelector('text');var tb=gb.querySelector('text');if(ta&&tb){var tmp=ta.textContent;ta.textContent=tb.textContent;tb.textContent=tmp;}}break;case'AddNode':var gn=findNode(a.node_id);if(gn)gn.setAttribute('opacity','1');break;}}}function goTo(n){idx=Math.max(-1,Math.min(n,timeline.steps.length-1));progress.value=Math.max(0,idx);desc.textContent=idx>=0?timeline.steps[idx].description:'';counter.textContent=timeline.steps.length>0?(Math.max(0,idx+1))+'/'+timeline.steps.length:'';resetAll();for(var i=0;i<=idx;i++){applyStep(i);}}function tick(){if(idx<timeline.steps.length-1){goTo(idx+1);}else{pause();}}function play(){pause();var ms=idx>=0&&idx<timeline.steps.length?timeline.steps[idx].duration_ms:400;timer=setInterval(tick,ms/speed);playBtn.textContent='\u23F8';}function pause(){if(timer){clearInterval(timer);timer=null;}playBtn.textContent='\u25B6';}root.querySelector('[data-action=prev]').addEventListener('click',function(){pause();goTo(idx-1);});playBtn.addEventListener('click',function(){if(timer){pause();}else{play();}});root.querySelector('[data-action=next]').addEventListener('click',function(){pause();goTo(idx+1);});progress.addEventListener('input',function(){pause();goTo(parseInt(progress.value));});root.querySelector('[data-action=speed]').addEventListener('change',function(e){speed=parseFloat(e.target.value);if(timer){play();}});})()</script>
    ),
  )

  buf.write_string("</div>")
  buf.to_string()
}
