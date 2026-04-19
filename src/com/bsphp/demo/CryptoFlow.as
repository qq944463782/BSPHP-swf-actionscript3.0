package com.bsphp.demo {
    import com.hurlant.crypto.Crypto;
    import com.hurlant.crypto.hash.IHash;
    import com.hurlant.crypto.rsa.RSAKey;
    import com.hurlant.crypto.symmetric.ICipher;
    import com.hurlant.crypto.symmetric.IVMode;
    import com.hurlant.crypto.symmetric.PKCS5;
    import com.hurlant.util.Base64;
    import com.hurlant.util.Hex;
    import com.hurlant.util.der.DER;
    import com.hurlant.util.der.PEM;
    import flash.utils.ByteArray;

    public class CryptoFlow {
        private static var cachedPublicKey:RSAKey;
        private static var cachedPrivateKey:RSAKey;

        public static function buildPacket(
            api:String,
            sessl:String,
            mutualKey:String,
            serverPrivateKeyDerB64:String,
            clientPublicKeyDerB64:String,
            extra:Object
        ):Object {
            var steps:Array = [];
            var dateNormal:String = nowString(" ");
            var dateHash:String = nowString("#");
            var appSafeCode:String = md5Hex(dateNormal);

            var params:Object = {
                api: api,
                BSphpSeSsL: sessl,
                date: dateHash,
                md5: "",
                mutualkey: mutualKey,
                appsafecode: appSafeCode
            };
            merge(params, extra);

            var plainWithoutMd5:String = encodeParams(params);
            params.md5 = md5Hex(plainWithoutMd5);
            var plain:String = encodeParams(params);
            var aesKey:String = md5Hex(serverPrivateKeyDerB64 + appSafeCode).substr(0, 16);
            var encryptedB64:String = aes128CbcEncryptBase64(plain, aesKey);
            var sigMd5:String = md5Hex(encryptedB64);
            var signature:String = "0|AES-128-CBC|" + aesKey + "|" + sigMd5 + "|" + BsphpConfig.SIGNATURE_TAIL;
            var rsaB64:String = rsaEncryptPkcs1Base64(signature, clientPublicKeyDerB64);
            var payload:String = encryptedB64 + "|" + rsaB64;
            var transportBody:String = "parameter=" + urlEncode(payload);

            steps.push("[crypto] step1 appsafecode=md5(dateNormal) => " + appSafeCode);
            steps.push("[crypto] step2 md5=md5(plain_without_md5) => " + params.md5);
            steps.push("[crypto] step3 plain(urlencoded)=" + plain);
            steps.push("[crypto] step4 aesKey=md5(serverKey+appsafe)[0..15] => " + aesKey);
            steps.push("[crypto] step5 aes-128-cbc(base64) length=" + encryptedB64.length);
            steps.push("[crypto] step6 sign=0|AES-128-CBC|key|md5(cipher)|json");
            steps.push("[crypto] step7 rsa(pkcs1)+payload+urlencode done");

            return {
                appSafeCode: appSafeCode,
                plain: plain,
                aesKey: aesKey,
                encryptedB64: encryptedB64,
                signature: signature,
                rsaB64: rsaB64,
                transportBody: transportBody,
                steps: steps
            };
        }

        public static function decryptResponse(rawBody:String, serverPrivateKeyDerB64:String, steps:Array):Object {
            var raw:String = urlDecode(rawBody);
            steps.push("[crypto] resp1 urldecode ok");
            var parts:Array = raw.split("|");
            if (parts.length < 2) {
                return {code: "", data: "bad response", appsafecode: "", sessl: ""};
            }

            var encryptedB64:String;
            var signatureB64:String;
            if (parts.length >= 3 && parts[0].substr(0, 2).toLowerCase() == "ok") {
                encryptedB64 = parts[1];
                signatureB64 = parts[2];
            } else {
                encryptedB64 = parts[0];
                signatureB64 = parts[1];
            }

            var sigPlain:String = rsaDecryptPkcs1Base64(signatureB64, serverPrivateKeyDerB64);
            steps.push("[crypto] resp2 rsa decrypt signature ok");
            var sigParts:Array = sigPlain.split("|");
            if (sigParts.length < 4) {
                return {code: "", data: "bad signature format", appsafecode: "", sessl: ""};
            }
            var aesKey:String = String(sigParts[2]).substr(0, 16);
            var decrypted:String = aes128CbcDecryptBase64(encryptedB64, aesKey);
            steps.push("[crypto] resp3 aes decrypt ok");
            return parseResponse(decrypted);
        }

        public static function parseResponse(raw:String):Object {
            if (!raw || raw.length == 0) {
                return {code: "", data: "", appsafecode: "", sessl: ""};
            }

            if (raw.indexOf("<") == 0 || raw.indexOf("<?xml") == 0) {
                return {
                    code: readXmlTag(raw, "code"),
                    data: readXmlTag(raw, "data"),
                    appsafecode: readXmlTag(raw, "appsafecode"),
                    sessl: readXmlTag(raw, "SeSsL")
                };
            }

            var obj:Object;
            try {
                obj = JSON.parse(raw);
            } catch (e:Error) {
                obj = {};
            }

            var payload:Object = obj.response ? obj.response : obj;
            return {
                code: payload.code || "",
                data: payload.data || "",
                appsafecode: payload.appsafecode || "",
                sessl: payload.SeSsL || payload.sessl || ""
            };
        }

        private static function merge(to:Object, from:Object):void {
            if (!from) {
                return;
            }
            for (var key:String in from) {
                to[key] = from[key];
            }
        }

        private static function nowString(separator:String):String {
            var d:Date = new Date();
            return d.fullYear + "-" + pad(d.month + 1) + "-" + pad(d.date) + separator + pad(d.hours) + ":" + pad(d.minutes) + ":" + pad(d.seconds);
        }

        private static function pad(v:int):String {
            return v < 10 ? "0" + v : String(v);
        }

        private static function encodeParams(params:Object):String {
            var parts:Array = [];
            for (var key:String in params) {
                parts.push(urlEncode(key) + "=" + urlEncode(String(params[key])));
            }
            return parts.join("&");
        }

        public static function md5Hex(input:String):String {
            var hash:IHash = Crypto.getHash("md5");
            var src:ByteArray = utf8Bytes(input);
            src.position = 0;
            var digest:ByteArray = hash.hash(src);
            digest.position = 0;
            return Hex.fromArray(digest);
        }

        public static function aes128CbcEncryptBase64(plain:String, key16:String):String {
            var keyBytes:ByteArray = utf8Bytes(key16);
            var plainBytes:ByteArray = utf8Bytes(plain);
            var cipher:ICipher = Crypto.getCipher("aes-128-cbc", keyBytes, new PKCS5());
            IVMode(cipher).IV = copyBytes(keyBytes);
            cipher.encrypt(plainBytes);
            plainBytes.position = 0;
            return Base64.encodeByteArray(plainBytes);
        }

        public static function aes128CbcDecryptBase64(cipherB64:String, key16:String):String {
            var keyBytes:ByteArray = utf8Bytes(key16);
            var cipherBytes:ByteArray = Base64.decodeToByteArray(cipherB64);
            var cipher:ICipher = Crypto.getCipher("aes-128-cbc", keyBytes, new PKCS5());
            IVMode(cipher).IV = copyBytes(keyBytes);
            cipher.decrypt(cipherBytes);
            cipherBytes.position = 0;
            return cipherBytes.readUTFBytes(cipherBytes.length);
        }

        public static function rsaEncryptPkcs1Base64(message:String, publicKeyDerB64:String):String {
            if (cachedPublicKey == null) {
                var pubPem:String = makePem("PUBLIC KEY", publicKeyDerB64);
                cachedPublicKey = PEM.readRSAPublicKey(pubPem);
            }

            var src:ByteArray = utf8Bytes(message);
            var dst:ByteArray = new ByteArray();
            cachedPublicKey.encrypt(src, dst, src.length);
            dst.position = 0;
            return Base64.encodeByteArray(dst);
        }

        public static function rsaDecryptPkcs1Base64(cipherB64:String, privateKeyDerB64:String):String {
            if (cachedPrivateKey == null) {
                cachedPrivateKey = parsePkcs8PrivateKey(privateKeyDerB64);
            }

            var src:ByteArray = Base64.decodeToByteArray(cipherB64);
            var dst:ByteArray = new ByteArray();
            cachedPrivateKey.decrypt(src, dst, src.length);
            dst.position = 0;
            return dst.readUTFBytes(dst.length);
        }

        private static function parsePkcs8PrivateKey(privateKeyDerB64:String):RSAKey {
            var topBytes:ByteArray = Base64.decodeToByteArray(privateKeyDerB64);
            topBytes.position = 0;
            var top:* = DER.parse(topBytes);

            var octet:ByteArray = top[2] as ByteArray;
            octet.position = 0;
            var pkcs1:* = DER.parse(octet);
            return new RSAKey(
                pkcs1[1], int(pkcs1[2].valueOf()),
                pkcs1[3], pkcs1[4], pkcs1[5], pkcs1[6], pkcs1[7], pkcs1[8]
            );
        }

        private static function makePem(type:String, b64Der:String):String {
            return "-----BEGIN " + type + "-----\n" + chunk64(b64Der) + "\n-----END " + type + "-----";
        }

        private static function chunk64(s:String):String {
            var out:Array = [];
            var i:int = 0;
            while (i < s.length) {
                out.push(s.substr(i, 64));
                i += 64;
            }
            return out.join("\n");
        }

        public static function urlEncode(value:String):String {
            var bytes:ByteArray = utf8Bytes(value);
            var out:String = "";
            for (var i:int = 0; i < bytes.length; i++) {
                var c:int = bytes[i] & 0xFF;
                if (isUnreserved(c)) {
                    out += String.fromCharCode(c);
                } else {
                    var hex:String = c.toString(16).toUpperCase();
                    if (hex.length < 2) {
                        hex = "0" + hex;
                    }
                    out += "%" + hex;
                }
            }
            return out;
        }

        public static function urlDecode(value:String):String {
            var out:ByteArray = new ByteArray();
            var i:int = 0;
            while (i < value.length) {
                var ch:String = value.charAt(i);
                if (ch == "%" && i + 2 < value.length) {
                    var hex:String = value.substr(i + 1, 2);
                    out.writeByte(parseInt(hex, 16));
                    i += 3;
                } else {
                    out.writeByte(value.charCodeAt(i) & 0xFF);
                    i += 1;
                }
            }
            out.position = 0;
            return out.readUTFBytes(out.length);
        }

        private static function isUnreserved(c:int):Boolean {
            return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 45 || c == 95 || c == 46 || c == 126;
        }

        private static function utf8Bytes(s:String):ByteArray {
            var b:ByteArray = new ByteArray();
            b.writeUTFBytes(s);
            b.position = 0;
            return b;
        }

        private static function copyBytes(src:ByteArray):ByteArray {
            var out:ByteArray = new ByteArray();
            src.position = 0;
            out.writeBytes(src);
            out.position = 0;
            return out;
        }

        private static function readXmlTag(xml:String, tag:String):String {
            var startTag:String = "<" + tag + ">";
            var endTag:String = "</" + tag + ">";
            var start:int = xml.indexOf(startTag);
            if (start < 0) {
                return "";
            }
            start += startTag.length;
            var end:int = xml.indexOf(endTag, start);
            if (end < 0) {
                return "";
            }
            return xml.substring(start, end);
        }

    }
}
