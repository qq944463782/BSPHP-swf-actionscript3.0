package com.bsphp.demo {
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class BsphpClient {
        public var session:String = "";
        public var demoMode:Boolean = false;

        public function BsphpClient() {}

        public function bootstrap(onDone:Function, onSteps:Function):void {
            callApi("internet.in", {}, function(r1:Object):void {
                if (r1.data != "1") {
                    onDone(false, "internet.in failed");
                    return;
                }
                callApi("BSphpSeSsL.in", {}, function(r2:Object):void {
                    session = r2.sessl != "" ? r2.sessl : r2.data;
                    onDone(session != "", "sessl=" + session);
                }, onSteps);
            }, onSteps);
        }

        public function getNotice(onDone:Function, onSteps:Function):void {
            callApi("gg.in", {}, onDone, onSteps);
        }

        public function getVersion(onDone:Function, onSteps:Function):void {
            callApi("v.in", {}, onDone, onSteps);
        }

        public function getEndTime(onDone:Function, onSteps:Function):void {
            callApi("vipdate.lg", {}, onDone, onSteps);
        }

        public function getCodeEnabled(type:String, onDone:Function, onSteps:Function):void {
            callApi("getsetimag.in", {type: type}, onDone, onSteps);
        }

        public function registerUser(
            user:String,
            pwd:String,
            pwdb:String,
            coode:String,
            machineCode:String,
            onDone:Function,
            onSteps:Function
        ):void {
            callApi("registration.lg", {
                user: user,
                pwd: pwd,
                pwdb: pwdb,
                coode: coode,
                mobile: "",
                mibao_wenti: "demo_question",
                mibao_daan: "demo_answer",
                qq: "",
                mail: "",
                key: machineCode,
                extension: ""
            }, onDone, onSteps);
        }

        public function loginUser(
            user:String,
            pwd:String,
            coode:String,
            machineCode:String,
            onDone:Function,
            onSteps:Function
        ):void {
            callApi("login.lg", {
                user: user,
                pwd: pwd,
                coode: coode,
                key: machineCode,
                maxoror: machineCode
            }, function(resp:Object):void {
                if ((resp.code == "1011" || resp.code == "9908") && resp.sessl != "") {
                    session = resp.sessl;
                }
                onDone(resp);
            }, onSteps);
        }

        public function logout(onDone:Function, onSteps:Function):void {
            callApi("cancellation.lg", {}, function(resp:Object):void {
                session = "";
                onDone(resp);
            }, onSteps);
        }

        public function callCustomApi(api:String, params:Object, onDone:Function, onSteps:Function):void {
            callApi(api, params ? params : {}, onDone, onSteps);
        }

        private function callApi(api:String, params:Object, onDone:Function, onSteps:Function):void {
            var packet:Object;
            try {
                packet = CryptoFlow.buildPacket(
                    api, session, BsphpConfig.MUTUAL_KEY, BsphpConfig.SERVER_KEY, BsphpConfig.CLIENT_KEY, params
                );
            } catch (err:Error) {
                onDone({code: "crypto_error", data: err.message, appsafecode: "", sessl: ""});
                return;
            }
            onSteps(packet.steps);

            if (demoMode) {
                onDone(mockResponse(api, packet.appSafeCode));
                return;
            }

            var req:URLRequest = new URLRequest(BsphpConfig.URL);
            req.method = URLRequestMethod.POST;
            req.contentType = "application/x-www-form-urlencoded";
            req.data = packet.transportBody;

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, function(e:Event):void {
                var raw:String = String(loader.data);
                var rspSteps:Array = [];
                var resp:Object;
                try {
                    resp = CryptoFlow.decryptResponse(raw, BsphpConfig.SERVER_KEY, rspSteps);
                } catch (err:Error) {
                    resp = {code: "decrypt_error", data: err.message, appsafecode: "", sessl: ""};
                }
                onSteps(rspSteps);
                onDone(resp);
            });
            loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
                onDone({code: "io_error", data: e.text, appsafecode: "", sessl: ""});
            });
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
                onDone({code: "security_error", data: e.text, appsafecode: "", sessl: ""});
            });
            loader.load(req);
        }

        private function mockResponse(api:String, appSafeCode:String):Object {
            if (api == "internet.in") {
                return {code: "1001", data: "1", appsafecode: appSafeCode, sessl: ""};
            }
            if (api == "BSphpSeSsL.in") {
                return {code: "1001", data: "ok", appsafecode: appSafeCode, sessl: "SESSL_DEMO_" + int(Math.random() * 100000)};
            }
            if (api == "gg.in") {
                return {code: "1001", data: "欢迎使用 AS3 登录演示，当前为本地 demoMode。", appsafecode: appSafeCode, sessl: ""};
            }
            if (api == "registration.lg") {
                return {code: "1009", data: "注册成功（演示）", appsafecode: appSafeCode, sessl: ""};
            }
            if (api == "login.lg") {
                return {code: "1011", data: "登录成功（演示）", appsafecode: appSafeCode, sessl: "LOGIN_SESSL_" + int(Math.random() * 100000)};
            }
            return {code: "1001", data: "ok", appsafecode: appSafeCode, sessl: ""};
        }
    }
}
