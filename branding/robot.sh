#!/usr/bin/env bash
# Renders the robot with headless Chrome, all 512 x 512,
# transparent and cropped to the same square around the robot:
#   assets/images/robot.png        the game character
#   assets/images/robot_back.png   from behind, from robot_front_source.png
#   assets/images/robot_front.png  facing the child, from robot_front_source.png
#   assets/images/robot_head.png   the splash screen's head (everything above
#   assets/images/robot_body.png   the neck) and body, drawn apart so the
#                                  head can bob while the wheels roll
# The robot was designed with Recraft V3 (on fal.ai, no longer used). Its
# faces are drawn by the app over the screen (paintRobotFace), and the splash
# draws spokes over the wheel hubs (RollingRobot), so a new picture must keep
# the screen and hubs in the same places, or those must move with it.
# Run from the project root:
#   branding/robot.sh
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP:?}"' EXIT

# Shapes ending above this line (in the SVG's units) belong to the head.
NECK=1350

# render <layer: all|head|body> <out.png>
render() {
  {
    printf '<!doctype html><html><body style="margin:0;background:transparent"><div style="width:512px;height:512px">'
    cat branding/robot.svg
    printf '</div><script>
const layer="%s", neck=%s, ns="http://www.w3.org/2000/svg";
const svg=document.querySelector("svg");
svg.removeAttribute("width");svg.removeAttribute("height");
svg.style.width="512px";svg.style.height="512px";
const b=svg.getBBox();const side=Math.max(b.width,b.height)*1.04;
svg.setAttribute("viewBox",[b.x+b.width/2-side/2,b.y+b.height/2-side/2,side,side].join(" "));
svg.setAttribute("preserveAspectRatio","xMidYMid meet");
if(layer==="head"||layer==="body"){
  // The first shape is the outline of the whole robot: cut it at the neck,
  // below the rounded bottom of the head, so none of it peeks out as the head bobs.
  const defs=svg.querySelector("defs")||svg.insertBefore(document.createElementNS(ns,"defs"),svg.firstChild);
  const clip=document.createElementNS(ns,"clipPath");clip.id="part";
  const r=document.createElementNS(ns,"rect");
  r.setAttribute("x",b.x-10);r.setAttribute("width",b.width+20);
  if(layer==="head"){r.setAttribute("y",b.y-10);r.setAttribute("height",neck-b.y+10);}
  else{r.setAttribute("y",neck);r.setAttribute("height",b.y+b.height-neck+10);}
  clip.appendChild(r);defs.appendChild(clip);
  const paths=[...svg.querySelectorAll("path")];
  paths.forEach((p,i)=>{
    if(i===0){p.setAttribute("clip-path","url(#part)");return;}
    const pb=p.getBBox();const head=pb.y+pb.height<=neck;
    if(head!==(layer==="head"))p.remove();
  });
}
</script></body></html>' "$1" "$NECK"
  } > "$TMP/robot.html"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
    --window-size=512,512 --screenshot="$PWD/$2" "file://$TMP/robot.html" 2>/dev/null
  echo "$2"
}

render all assets/images/robot.png
render head assets/images/robot_head.png
render body assets/images/robot_body.png

# The robot facing the child comes from a picture (the user's reference,
# branding/robot_front_source.png); tool/robot/front.html clears its
# background, erases its face and fits it into the same frame.
cp tool/robot/front.html "$TMP/front.html"
cp branding/robot_front_source.png "$TMP/source.png"
for view in front back; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --virtual-time-budget=5000 --default-background-color=00000000 \
    --window-size=512,512 --screenshot="$PWD/assets/images/robot_$view.png" \
    "file://$TMP/front.html?$view" 2>/dev/null
  echo "assets/images/robot_$view.png"
done
