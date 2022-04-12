<html>
    <head>
        <meta content="text/html; charset=utf-8" http-equiv="content-type"/>
        <meta name="viewport" content="width=device-width, shrink-to-fit=YES" />
    </head>

    <body>
        <div style="height: 150px; overflow: scroll; border:solid 1px green;" id="logScroll">
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
    </body>
    <script>

    const IS_TEST = true

    const KEY = {
        requestIDWeb: 'requestIDWeb',
        requestIDSwift: 'requestIDSwift'
    }

    function WKWebViewJSBridge() {
        if (window.app) { return; }
        window.app = function() {
            var callbacks = {}
            
            function receiveWeb(data) {
                console.log('receiveWeb');
                // process
                var jsonObj = processWeb(data)
                if (jsonObj[KEY.requestIDWeb] && receivePool[jsonObj[KEY.requestIDWeb]]) {
                    receivePool[jsonObj[KEY.requestIDWeb]](jsonObj);
                } else {
                    bridgeLog(jsonObj["title"] + ": " + jsonObj["result"]);
                    // request
                    if (IS_TEST) {
                        const delay = jsonObj["delay"]
                        if (jsonObj[KEY.requestIDSwift]) {
                            if (delay) {
                                setTimeout(function() {
                                    requestSwift(jsonObj);
                                }, delay * 1000);
                            } else {
                                requestSwift(jsonObj);
                            }
                        }
                    } else {
                        requestSwift(jsonObj);
                    }
                }
            }
            
            function processWeb(data) {
                var jsonObj = jsonObjFromBase64(data);                
                if (jsonObj[KEY.requestIDWeb] == null) {
                    jsonObj = processJSBridge(jsonObj)
                }
                return jsonObj
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
                "test2": function(data) {
                    console.log('Receive -> Web : ' + data);
                    requestSwift({"test": "test"}, "test2");
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

    const jsbridge = WKWebViewJSBridge();
    var receivePool = {};

    function bridgeLog(logContent) {
        document.getElementById("log").innerHTML += logContent + "\n";
        
        var logScroll = document.getElementById("logScroll");
        logScroll.scrollTop = logScroll.scrollHeight;
    }

    function uuidv4() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
            return v.toString(16);
        });
    }

    function requestSwift(param, path = "receiveNative", callback) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[path]) {
            const requestID = uuidv4()
            param[KEY.requestIDWeb] = requestID
            if (callback) {
                receivePool[requestID] = callback
            }
            
            const jsonString = btoa(encodeURIComponent(JSON.stringify(param)));
            console.log('Request -> Native : ' + jsonString);
            window.webkit.messageHandlers[path].postMessage(jsonString);
        }
    }

    function OnlyRequest() {
        requestSwift({"title": "Only Requests from Web"}, "OnlyRequest");
    }

    function RoundRequest() {
        requestSwift({"title": "Round Requests from Web"}, "RoundRequest", function(jsonObj) {
            bridgeLog(jsonObj["title"]);
        });
    }

    function MultiRequest() {
        requestSwift({"title": "Multi Requests from Web 1", "delay":3}, "MultiRequest", function(jsonObj) {
            bridgeLog(jsonObj["title"]);
        });
        requestSwift({"title": "Multi Requests from Web 2", "delay":1}, "MultiRequest", function(jsonObj) {
            bridgeLog(jsonObj["title"]);
        });
    }

    </script>
</html>
