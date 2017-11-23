<html>
<head>
    <title>Text fade in – fade out Animation</title>
    <style>
        canvas{border: 1px solid #bbb;}
        .subdiv{width: 320px;}
        .text{margin: auto; width: 290px;}
    </style>
 
    <script type="text/javascript">
        var can, ctx, step = 50, steps = 255;
              delay = 20;
              var rgbstep = 50;
 
        var text1 = "The first news have to do with the success of a man doing AI";
        var text2 = "Second big news.  We are going to sleep early in the winter.";
        var text;

        var maxWidth;
        var lineHeight;
        
        function init() {
            can = document.getElementById("MyCanvas1");
            ctx= can.getContext("2d");
            ctx.fillStyle = "blue";
            ctx.font = "12pt Helvetica";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            maxWidth = 200;
            lineHeight = 25;
            text = text1;
            Textfadeup();
       }
 
       function Textfadeup() {
            rgbstep++;
            ctx.clearRect(0, 0, can.width, can.height);
            ctx.fillStyle = "rgb(" + rgbstep + "," + rgbstep + "," + rgbstep + ")"
            //ctx.fillText(text, 150, 100);
            wrapText(ctx, text, 150, 100, maxWidth, lineHeight)
            if (rgbstep < 255)
                var t = setTimeout('Textfadeup()', delay);
            if (rgbstep == 255) {
            	if (text == text1)
            		text = text2;
            	else
            		text = text1;
                Textfadedown();
            }
        }
        function Textfadedown() {
			rgbstep=rgbstep-1;
            ctx.clearRect(0, 0, can.width, can.height);
            ctx.fillStyle = "rgb(" + rgbstep + "," + rgbstep + "," + rgbstep + ")"
            //ctx.fillText(text, 150, 100);
            wrapText(ctx, text, 150, 100, maxWidth, 25)
            if (rgbstep > 80)
                var t = setTimeout('Textfadedown()', delay);
            if (rgbstep == 80) {
                Textfadeup();
            }
        }
        
        
		function wrapText(context, text, x, y, maxWidth, lineHeight) {
			var words = text.split(' ');
			var line = '';

			for (var n = 0; n < words.length; n++) {
				var testLine = line + words[n] + ' ';
				var metrics = context.measureText(testLine);
				var testWidth = metrics.width;
				if (testWidth > maxWidth && n > 0) {
					context.fillText(line, x, y);
					line = words[n] + ' ';
					y += lineHeight;
				} else {
					line = testLine;
				}
			}
			context.fillText(line, x, y);
		}
		
	</script>
 
</head>
<body onload="init();">
    <div class="subdiv">
        <canvas id="MyCanvas1" width="300" height="200">
  This browser or document mode doesn't support canvas object</canvas>
          </div>
</body>
</html>