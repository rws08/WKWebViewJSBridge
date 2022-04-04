<html>
    <head>
        <meta content="text/html; charset=utf-8" http-equiv="content-type"/>
        <meta name="viewport" content="width=device-width, shrink-to-fit=YES" />
    </head>

    <body>
        <div style="height: 100px; overflow: scroll; border:solid 1px green;" id="logScroll">
            <xmp id="log" style="font-size: 12"></xmp>
        </div>
        <p>
            <input type="button" id="btnRequest1" value="Only Request" onclick="OnlyRequest();"
            />
        </p>
        <p>
            <input type="button" id="btnRequest2" value="Round Request" onclick="RoundRequest();"
            />
        </p>
        <p>
            <input type="button" id="btnRequest3" value="Multi Request" onclick="MultiRequest();"
            />
        </p>
        <p>
            <input type="button" id="btnRequest4" value="Custom Request" onclick="CustomRequest();"
            />
        </p>
    </body>
    <script>

    const KEY = {
        requestIDWeb: 'requestIDWeb',
        requestIDSwift: 'requestIDSwift',
        requestAll: 'requestAll'
    }

    function WKWebViewJSBridge() {
        if (window.app) { return; }
        window.app = function() {
            var callbacks = {}
            
            function receiveWeb(data) {
                console.log('receiveWeb');
                var jsonObj = jsonObjFromBase64(data);
                const delay = jsonObj["delay"]
                jsonObj = processJSBridge(jsonObj)
                bridgeLog(jsonObj["title"] + ": "+ jsonObj["result"] + ": " + delay);
                
                if (jsonObj[KEY.requestIDSwift]) {
                    if (delay) {
                        setTimeout(function() {
                            requestSwift(jsonObj);
                        }, delay * 1000);
                    } else {
                        requestSwift(jsonObj);
                    }
                }
            }
            
            function customRequest(data) {
                console.log('CustomRequest');
            }
            
            return {
                "receiveWeb": function(data) {
                    console.log('Receive -> Web : ' + data);
                    receiveWeb(data);
                },
                "OnlyRequest": function(data) {
                    console.log('Receive -> Web : ' + data);
                    receiveWeb(data);
                },
                "RoundRequest": function(data) {
                    console.log('Receive -> Web : ' + data);
                    receiveWeb(data);
                },
                "MultiRequest": function(data) {
                    console.log('Receive -> Web : ' + data);
                    receiveWeb(data);
                },
                "CustomRequest": function(data) {
                    console.log('Receive -> Web : ' + data);
                    customRequest(data);
                }
            }
        }()
        
        function processJSBridge(jsonObj) {
            jsonObj["result"] = true
            jsonObj["title"] += ", processed on web"
            return jsonObj;
        }
        
        function jsonObjFromBase64(base64) {
            const jsonString = decodeURIComponent(atob(base64));
            return JSON.parse(jsonString);
        }
        
        function rand(min, max) {
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }
    }

    var jsbridge = WKWebViewJSBridge();

    function bridgeLog(logContent) {
        document.getElementById("log").innerHTML += logContent + "\n";
        
        var logScroll = document.getElementById("logScroll");
        logScroll.scrollTop = logScroll.scrollHeight;
    }

    function requestSwift(path, param, callback) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.receiveNative) {
            var jsonObj = param
            if (path) {
                jsonObj[KEY.requestPath] = path
            }
            const jsonString = btoa(encodeURIComponent(JSON.stringify(jsonObj)));
            console.log('Request -> Native : ' + jsonString);
            window.webkit.messageHandlers.receiveNative.postMessage(jsonString);
        }
    }

    function OnlyRequest() {
        requestSwift("OnlyRequest", {"title": "Only Requests from Web"});
    }

    function RoundRequest() {
        
    }

    function MultiRequest() {
        
    }

    function CustomRequest() {
        
    }

    </script>
</html>
