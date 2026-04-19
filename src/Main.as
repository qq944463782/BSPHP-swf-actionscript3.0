package {
    import com.bsphp.demo.BsphpClient;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;

    public class Main extends Sprite {
        private var client:BsphpClient;

        private var userInput:TextField;
        private var pwdInput:TextField;
        private var pwd2Input:TextField;
        private var codeInput:TextField;
        private var machineInput:TextField;
        private var codeTypeInput:TextField;
        private var customApiInput:TextField;
        private var customParamsInput:TextField;
        private var noticeOutput:TextField;
        private var statusOutput:TextField;
        private var logOutput:TextField;

        public function Main() {
            initUI();
            client = new BsphpClient();
            appendLog("BSPHP AS3 real protocol mode ready. Click init to start.");
        }

        private function initUI():void {
            graphics.beginFill(0xEEF3FF);
            graphics.drawRect(0, 0, 940, 700);
            graphics.endFill();

            var title:TextField = new TextField();
            title.defaultTextFormat = new TextFormat("_sans", 22, 0x1C2A53, true);
            title.selectable = false;
            title.text = "BSPHP ActionScript 3.0 控制台";
            title.x = 18;
            title.y = 12;
            title.width = 430;
            title.height = 34;
            addChild(title);

            statusOutput = new TextField();
            statusOutput.defaultTextFormat = new TextFormat("_sans", 12, 0x2F4A8A, true);
            statusOutput.selectable = false;
            statusOutput.text = "session: (empty)";
            statusOutput.x = 460;
            statusOutput.y = 20;
            statusOutput.width = 460;
            statusOutput.height = 24;
            addChild(statusOutput);

            var formTf:TextFormat = new TextFormat("_sans", 13, 0x243255);
            var card1:Sprite = createCard(20, 56, 430, 264, "账号参数");
            addChild(card1);
            var card2:Sprite = createCard(468, 56, 452, 264, "快捷操作");
            addChild(card2);
            var card3:Sprite = createCard(20, 330, 900, 110, "公告与接口结果");
            addChild(card3);
            var card4:Sprite = createCard(20, 450, 900, 230, "加密流程与调试日志");
            addChild(card4);

            addLabel("账号", 34, 92, formTf);
            userInput = addInput("admin", 120, 88, 300, formTf);

            addLabel("密码", 34, 127, formTf);
            pwdInput = addInput("admin", 120, 123, 300, formTf);

            addLabel("确认密码", 34, 162, formTf);
            pwd2Input = addInput("admin", 120, 158, 300, formTf);

            addLabel("验证码", 34, 197, formTf);
            codeInput = addInput("1234", 120, 193, 300, formTf);

            addLabel("机器码", 34, 232, formTf);
            machineInput = addInput("as3-demo-machine", 120, 228, 300, formTf);

            addLabel("验证码开关查询", 34, 267, formTf);
            codeTypeInput = addInput("INGES_LOGIN|INGES_RE|INGES_MACK|INGES_SAY", 120, 263, 300, formTf);

            addActionButton("初始化会话", 486, 88, 130, onBootstrapClick);
            addActionButton("获取公告", 628, 88, 130, onGetNoticeClick);
            addActionButton("获取版本", 770, 88, 130, onGetVersionClick);

            addActionButton("注册", 486, 128, 130, onRegisterClick);
            addActionButton("登录", 628, 128, 130, onLoginClick);
            addActionButton("注销", 770, 128, 130, onLogoutClick);

            addActionButton("检测到期", 486, 168, 130, onGetEndTimeClick);
            addActionButton("查验证码开关", 628, 168, 130, onCodeEnabledClick);
            addActionButton("清空日志", 770, 168, 130, onClearLogClick);

            addLabel("自定义 API", 486, 220, formTf);
            customApiInput = addInput("appcustom.in", 566, 216, 160, formTf);
            addLabel("参数(k=v&...)", 734, 220, formTf);
            customParamsInput = addInput("info=myapp", 820, 216, 92, formTf);
            addActionButton("发送", 770, 256, 130, onCustomApiClick);

            noticeOutput = addOutput(34, 366, 872, 62, new TextFormat("_sans", 13, 0x1D2D52));
            logOutput = addOutput(34, 486, 872, 180, new TextFormat("_typewriter", 12, 0x0D1F40));
        }

        private function onBootstrapClick(e:MouseEvent):void {
            appendLog("==== bootstrap start ====");
            client.bootstrap(function(ok:Boolean, info:String):void {
                appendStatus(ok ? "OK" : "ERR", "bootstrap", info);
            }, appendSteps);
        }

        private function onGetNoticeClick(e:MouseEvent):void {
            appendLog("==== get notice ====");
            client.getNotice(function(resp:Object):void {
                noticeOutput.text = "[code=" + resp.code + "] " + resp.data;
                appendApiResult("gg.in", resp);
                refreshSessionStatus();
            }, appendSteps);
        }

        private function onGetVersionClick(e:MouseEvent):void {
            appendLog("==== get version ====");
            client.getVersion(function(resp:Object):void {
                noticeOutput.text = "[version] code=" + resp.code + " data=" + resp.data;
                appendApiResult("v.in", resp);
            }, appendSteps);
        }

        private function onGetEndTimeClick(e:MouseEvent):void {
            appendLog("==== get end time ====");
            client.getEndTime(function(resp:Object):void {
                noticeOutput.text = "[vipdate] code=" + resp.code + " data=" + resp.data;
                appendApiResult("vipdate.lg", resp);
            }, appendSteps);
        }

        private function onRegisterClick(e:MouseEvent):void {
            appendLog("==== register ====");
            client.registerUser(
                userInput.text,
                pwdInput.text,
                pwd2Input.text,
                codeInput.text,
                machineInput.text,
                function(resp:Object):void {
                    appendApiResult("registration.lg", resp);
                },
                appendSteps
            );
        }

        private function onLoginClick(e:MouseEvent):void {
            appendLog("==== login ====");
            client.loginUser(
                userInput.text,
                pwdInput.text,
                codeInput.text,
                machineInput.text,
                function(resp:Object):void {
                    appendApiResult("login.lg", resp);
                },
                appendSteps
            );
            refreshSessionStatus();
        }

        private function onLogoutClick(e:MouseEvent):void {
            appendLog("==== logout ====");
            client.logout(function(resp:Object):void {
                appendApiResult("cancellation.lg", resp);
                refreshSessionStatus();
            }, appendSteps);
        }

        private function onCodeEnabledClick(e:MouseEvent):void {
            appendLog("==== get code enabled ====");
            client.getCodeEnabled(codeTypeInput.text, function(resp:Object):void {
                noticeOutput.text = "[code-enabled] " + resp.data;
                appendApiResult("getsetimag.in", resp);
            }, appendSteps);
        }

        private function onCustomApiClick(e:MouseEvent):void {
            var api:String = customApiInput.text;
            if (api == null || api == "") {
                appendStatus("ERR", "custom", "api 不能为空");
                return;
            }
            appendLog("==== custom api ====");
            client.callCustomApi(api, parseParamText(customParamsInput.text), function(resp:Object):void {
                noticeOutput.text = "[custom] code=" + resp.code + " data=" + resp.data;
                appendApiResult(api, resp);
            }, appendSteps);
        }

        private function onClearLogClick(e:MouseEvent):void {
            logOutput.text = "";
            appendStatus("OK", "ui", "日志已清空");
        }

        private function appendSteps(steps:Array):void {
            for each (var line:String in steps) {
                appendLog(line);
            }
        }

        private function parseParamText(raw:String):Object {
            var out:Object = {};
            if (raw == null || raw == "") {
                return out;
            }
            var pairs:Array = raw.split("&");
            for each (var part:String in pairs) {
                if (part == "") {
                    continue;
                }
                var idx:int = part.indexOf("=");
                if (idx < 0) {
                    out[part] = "";
                } else {
                    out[part.substring(0, idx)] = part.substring(idx + 1);
                }
            }
            return out;
        }

        private function addLabel(text:String, xPos:Number, yPos:Number, format:TextFormat):void {
            var t:TextField = new TextField();
            t.defaultTextFormat = format;
            t.selectable = false;
            t.text = text;
            t.x = xPos;
            t.y = yPos;
            t.width = 80;
            t.height = 24;
            addChild(t);
        }

        private function addInput(value:String, xPos:Number, yPos:Number, width:Number, format:TextFormat):TextField {
            var t:TextField = new TextField();
            t.defaultTextFormat = format;
            t.type = TextFieldType.INPUT;
            t.border = true;
            t.background = true;
            t.backgroundColor = 0xFFFFFF;
            t.text = value;
            t.x = xPos;
            t.y = yPos;
            t.width = width;
            t.height = 26;
            addChild(t);
            return t;
        }

        private function addOutput(xPos:Number, yPos:Number, width:Number, height:Number, format:TextFormat):TextField {
            var t:TextField = new TextField();
            t.defaultTextFormat = format;
            t.border = true;
            t.background = true;
            t.backgroundColor = 0xFAFAFA;
            t.multiline = true;
            t.wordWrap = true;
            t.x = xPos;
            t.y = yPos;
            t.width = width;
            t.height = height;
            addChild(t);
            return t;
        }

        private function createCard(xPos:Number, yPos:Number, width:Number, height:Number, title:String):Sprite {
            var card:Sprite = new Sprite();
            card.x = xPos;
            card.y = yPos;
            card.graphics.beginFill(0xFFFFFF);
            card.graphics.drawRoundRect(0, 0, width, height, 14, 14);
            card.graphics.endFill();
            card.filters = [new DropShadowFilter(8, 90, 0x2A3E77, 0.15, 8, 8, 1)];

            var cap:TextField = new TextField();
            cap.defaultTextFormat = new TextFormat("_sans", 14, 0x2D3A63, true);
            cap.selectable = false;
            cap.text = title;
            cap.x = 14;
            cap.y = 10;
            cap.width = width - 20;
            cap.height = 24;
            card.addChild(cap);
            return card;
        }

        private function addActionButton(text:String, xPos:Number, yPos:Number, width:Number, clickHandler:Function):void {
            var btn:Sprite = new Sprite();
            drawButton(btn, width, 0x356AE6);
            btn.x = xPos;
            btn.y = yPos;
            btn.buttonMode = true;
            btn.mouseChildren = false;
            btn.addEventListener(MouseEvent.CLICK, clickHandler);
            btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {
                drawButton(btn, width, 0x4A7EF6);
            });
            btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {
                drawButton(btn, width, 0x356AE6);
            });

            var label:TextField = new TextField();
            label.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF, true);
            label.selectable = false;
            label.mouseEnabled = false;
            label.text = text;
            label.width = width;
            label.height = 24;
            label.x = 10;
            label.y = 5;
            btn.addChild(label);

            addChild(btn);
        }

        private function drawButton(btn:Sprite, width:Number, color:uint):void {
            btn.graphics.clear();
            btn.graphics.beginFill(color);
            btn.graphics.drawRoundRect(0, 0, width, 30, 8, 8);
            btn.graphics.endFill();
        }

        private function appendLog(line:String):void {
            if (logOutput.text.length > 0) {
                logOutput.appendText("\n");
            }
            logOutput.appendText("[" + nowTime() + "] " + line);
            logOutput.scrollV = logOutput.maxScrollV;
            refreshSessionStatus();
        }

        private function appendStatus(level:String, scope:String, message:String):void {
            appendLog("[" + level + "] [" + scope + "] " + message);
        }

        private function appendApiResult(api:String, resp:Object):void {
            var code:String = safeToString(resp.code);
            var data:String = safeToString(resp.data);
            var sessl:String = safeToString(resp.sessl);
            var level:String = classifyCode(code);
            var line:String = "[" + level + "] [" + api + "] code=" + code + " data=" + data;
            if (sessl != "") {
                line += " sessl=" + sessl;
            }
            appendLog(line);
        }

        private function classifyCode(code:String):String {
            if (code == "1001" || code == "1009" || code == "1011" || code == "9908") {
                return "OK";
            }
            if (code == "io_error" || code == "security_error" || code == "crypto_error" || code == "decrypt_error" || code == "") {
                return "ERR";
            }
            return "WARN";
        }

        private function safeToString(v:*):String {
            if (v === null || v === undefined) {
                return "";
            }
            return String(v);
        }

        private function nowTime():String {
            var d:Date = new Date();
            return pad2(d.hours) + ":" + pad2(d.minutes) + ":" + pad2(d.seconds);
        }

        private function refreshSessionStatus():void {
            var sessl:String = client ? client.session : "";
            if (sessl == null || sessl == "") {
                statusOutput.text = "session: (empty)";
                return;
            }
            if (sessl.length > 56) {
                sessl = sessl.substr(0, 28) + "..." + sessl.substr(sessl.length - 16);
            }
            statusOutput.text = "session: " + sessl;
        }

        private function pad2(n:int):String {
            return n < 10 ? "0" + n : String(n);
        }
    }
}
