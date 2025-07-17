//
//  FingerprintManager.swift
//  TagWorks-SDK-iOS-v1
//
//  Created by obzen on 6/17/25.
//

import Foundation
import UIKit
import WebKit

public class FingerprintManager: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    
    override public init() {}
    
    //    let fingerprintScript: String = """
    //    // <script>
    //    async function sha256(str) {
    //      const buffer = new TextEncoder().encode(str);
    //      const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
    //      return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");
    //    }
    //
    //    // 오차 유도: 부동소수점 미세 오차를 누적해 디바이스 차이 노출
    //    function floatingPointDrift(seed = 1.2345) {
    //      let x = seed;
    //      for (let i = 0; i < 1000; i++) {
    //        x = Math.fround(Math.sin(x * 1.1234567)) * 1.0000001 + 0.0000001;
    //      }
    //      return x.toFixed(10);
    //    }
    //
    //    // Canvas: 렌더링 정밀도, 안티앨리어싱 차이
    //    function getCanvasFingerprint() {
    //      const canvas = document.createElement("canvas");
    //      canvas.width = 300;
    //      canvas.height = 150;
    //      const ctx = canvas.getContext("2d");
    //
    //      ctx.textBaseline = "top";
    //      ctx.font = "18px Arial";
    //      ctx.fillStyle = "#000";
    //      ctx.imageSmoothingEnabled = false;
    //      ctx.fillText("Fingerprint Render", 10, 10);
    //
    //      const pixels = ctx.getImageData(0, 0, 300, 150).data;
    //      return Array.from(pixels).slice(0, 100).join(","); // 일부만 사용
    //    }
    //
    //    // WebGL: GPU vendor, renderer, float precision
    //    function getWebGLFingerprint() {
    //      const canvas = document.createElement("canvas");
    //      const gl = canvas.getContext("webgl");
    //      if (!gl) return "webgl-not-supported";
    //
    //      const debugInfo = gl.getExtension("WEBGL_debug_renderer_info");
    //      const vendor = debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : "unknown";
    //      const renderer = debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : "unknown";
    //      const precision = gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision;
    //
    //      return `${vendor}|${renderer}|${precision}`;
    //    }
    //
    //    // Audio: Float DSP 연산 기반 fingerprint
    //    async function getAudioFingerprint() {
    //      try {
    //        const ctx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 44100, 44100);
    //        const osc = ctx.createOscillator();
    //        osc.type = "triangle";
    //        osc.frequency.setValueAtTime(10000, ctx.currentTime);
    //
    //        const comp = ctx.createDynamicsCompressor();
    //        osc.connect(comp);
    //        comp.connect(ctx.destination);
    //
    //        osc.start();
    //        const buffer = await ctx.startRendering();
    //        const data = buffer.getChannelData(0).slice(0, 100);
    //        return Array.from(data).map(f => f.toFixed(5)).join(",");
    //      } catch {
    //        return "audio-error";
    //      }
    //    }
    //
    //    // Navigator 정보 기반 fingerprint
    //    function getNavigatorFingerprint() {
    //      return [
    //        navigator.userAgent,
    //        navigator.platform,
    //        navigator.language,
    //        navigator.languages?.join(','),
    //        navigator.hardwareConcurrency,
    //        Intl.DateTimeFormat().resolvedOptions().timeZone
    //      ].join("|");
    //    }
    //
    //    // 최종 fingerprint 조합
    //    async function generateDeviceFingerprint() {
    //      const noise = floatingPointDrift();
    //      const canvas = getCanvasFingerprint();
    //      const webgl = getWebGLFingerprint();
    //      const audio = await getAudioFingerprint();
    //      const nav = getNavigatorFingerprint();
    //
    //      const combined = [noise, canvas, webgl, audio, nav].join("||");
    //      const fingerprint = await sha256(combined);
    //      console.log("🔐 Device Fingerprint:", fingerprint);
    //      return fingerprint;
    //    }
    //
    //    // JavaScript 내에서 실행되도록 수정:
    //    generateDeviceFingerprint().then(fp => {
    //      window.webkit.messageHandlers.fingerprintHandler.postMessage(fp);
    //    });
    //
    //    // 실행 예시
    //    // generateDeviceFingerprint();
    //    // </script>
    //    """
    
    
    let fingerprintScript = """
            // js-sha256 핵심 부분 (압축된 원본 사용 권장)
            ;(function () {
              'use strict';
            
              var K = [
                0x428a2f98, 0x71374491, 0xb5c0fbcf,
                0xe9b5dba5, 0x3956c25b, 0x59f111f1,
                0x923f82a4, 0xab1c5ed5, 0xd807aa98,
                0x12835b01, 0x243185be, 0x550c7dc3,
                0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
                0xc19bf174, 0xe49b69c1, 0xefbe4786,
                0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
                0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                0x983e5152, 0xa831c66d, 0xb00327c8,
                0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
                0x06ca6351, 0x14292967, 0x27b70a85,
                0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
                0x650a7354, 0x766a0abb, 0x81c2c92e,
                0x92722c85, 0xa2bfe8a1, 0xa81a664b,
                0xc24b8b70, 0xc76c51a3, 0xd192e819,
                0xd6990624, 0xf40e3585, 0x106aa070,
                0x19a4c116, 0x1e376c08, 0x2748774c,
                0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
                0x5b9cca4f, 0x682e6ff3, 0x748f82ee,
                0x78a5636f, 0x84c87814, 0x8cc70208,
                0x90befffa, 0xa4506ceb, 0xbef9a3f7,
                0xc67178f2
              ];
            
              function rightRotate(value, amount) {
                return (value >>> amount) | (value << (32 - amount));
              }
            
              function sha256(ascii) {
                var maxWord = Math.pow(2, 32);
                var lengthProperty = 'length';
                var i, j;
                var result = '';
            
                var words = [];
                var asciiBitLength = ascii[lengthProperty] * 8;
            
                // 초기화
                var hash = [
                  0x6a09e667, 0xbb67ae85,
                  0x3c6ef372, 0xa54ff53a,
                  0x510e527f, 0x9b05688c,
                  0x1f83d9ab, 0x5be0cd19
                ];
            
                ascii += String.fromCharCode(0x80);
                while ((ascii[lengthProperty] % 64) - 56) ascii += String.fromCharCode(0x80);
            
                for (i = 0; i < ascii[lengthProperty]; i++) {
                  j = ascii.charCodeAt(i);
                  if (j >> 8) return;
                  words[i >> 2] |= j << (((3 - i) % 4) * 8);
                }
            
                words[words[lengthProperty]] = (asciiBitLength / maxWord) | 0;
                words[words[lengthProperty]] = asciiBitLength;
            
                for (j = 0; j < words[lengthProperty];) {
                  var w = words.slice(j, (j += 16));
                  var oldHash = hash.slice(0);
            
                  for (i = 16; i < 64; i++) {
                    var s0 =
                      rightRotate(w[i - 15], 7) ^
                      rightRotate(w[i - 15], 18) ^
                      (w[i - 15] >>> 3);
                    var s1 =
                      rightRotate(w[i - 2], 17) ^
                      rightRotate(w[i - 2], 19) ^
                      (w[i - 2] >>> 10);
                    w[i] = (w[i - 16] + s0 + w[i - 7] + s1) | 0;
                  }
            
                  var a = hash[0];
                  var b = hash[1];
                  var c = hash[2];
                  var d = hash[3];
                  var e = hash[4];
                  var f = hash[5];
                  var g = hash[6];
                  var h = hash[7];
            
                  for (i = 0; i < 64; i++) {
                    var s1 =
                      rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25);
                    var ch = (e & f) ^ (~e & g);
                    var temp1 = (h + s1 + ch + K[i] + w[i]) | 0;
                    var s0 =
                      rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22);
                    var maj = (a & b) ^ (a & c) ^ (b & c);
                    var temp2 = (s0 + maj) | 0;
            
                    h = g;
                    g = f;
                    f = e;
                    e = (d + temp1) | 0;
                    d = c;
                    c = b;
                    b = a;
                    a = (temp1 + temp2) | 0;
                  }
            
                  hash[0] = (hash[0] + a) | 0;
                  hash[1] = (hash[1] + b) | 0;
                  hash[2] = (hash[2] + c) | 0;
                  hash[3] = (hash[3] + d) | 0;
                  hash[4] = (hash[4] + e) | 0;
                  hash[5] = (hash[5] + f) | 0;
                  hash[6] = (hash[6] + g) | 0;
                  hash[7] = (hash[7] + h) | 0;
                }
            
                for (i = 0; i < hash.length; i++) {
                  for (j = 3; j + 1; j--) {
                    var b = (hash[i] >> (j * 8)) & 255;
                    result += (b < 16 ? '0' : '') + b.toString(16);
                  }
                }
                return result;
              }
            
              // 전역에 sha256 할당
              if (typeof window !== 'undefined') {
                window.sha256 = sha256;
              } else if (typeof global !== 'undefined') {
                global.sha256 = sha256;
              }
            })();
            
            
            async function generateDeviceFingerprint() {
            
              //async function sha256(str) {
              //  if (window.crypto && window.crypto.subtle && window.crypto.subtle.digest) {
              //    const buffer = new TextEncoder().encode(str);
              //    const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
              //    return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");
              //  } else {
              //    // 폴리필 또는 간단한 해시 (완벽하지 않음, 대체용)
              //    return simpleHash(str);
              //  }
              //}
            
            //async function sha256(str) {
            //  try {
            //    if (window.crypto && window.crypto.subtle && typeof window.crypto.subtle.digest === "function") {
            //      const buffer = new TextEncoder().encode(str);
            //      const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
            //      return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, "0")).join("");
            //    } else {
            //      return simpleHash(str); // fallback
            //    }
            //  } catch (e) {
            //    console.warn("SHA-256 실패, fallback 사용", e);
            //    return simpleHash(str);
            //  }
            // }
            
              // 매우 간단한 해시 예시 (비보안, 테스트용)
              function simpleHash(str) {
                let hash = 0, i, chr;
                if (str.length === 0) return hash.toString();
                for (i = 0; i < str.length; i++) {
                  chr = str.charCodeAt(i);
                  hash = ((hash << 5) - hash) + chr;
                  hash |= 0;
                }
                return hash.toString(16);
              }
            
              function floatingPointDrift(seed = 1.239487239487934349587349857467) {
                let x = seed;
                for (let i = 0; i < 1000; i++) {
                  x = Math.fround(Math.sin(x * 1.924835792878923234234897873486)) * 1.000000978457569384768345 + 0.0000001;
                }
                return x.toFixed(16);
              }
            
              function getCanvasFingerprint() {
              //    const noise = floatingPointDrift();  // noise 계산
              //
              //    const canvas = document.createElement("canvas");
              //    canvas.width = 300;
              //    canvas.height = 150;
              //    const ctx = canvas.getContext("2d");
              //
              //    ctx.textBaseline = "top";
              //    ctx.font = `${14 + (noise % 2)}px Arial`; // noise를 폰트 크기에 적용
              //    ctx.fillStyle = "#f60";
              //    ctx.fillRect(10, 10, 100, 50);
              //    ctx.fillStyle = "#069";
              //    ctx.rotate(0.05);
              //    ctx.fillText("🌎 Fingerprint Test 😎", 20, 20);
              //    ctx.globalAlpha = 0.7;
              //    ctx.strokeStyle = "#888";
              //    ctx.strokeRect(0, 0, 300, 150);
              //
              //    const pixels = ctx.getImageData(0, 0, 100, 100).data;
              //    return Array.from(pixels).slice(0, 100).join(",");
            
              //    //const pixels = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
              //    //return Array.from(pixels).slice(0, 500).join(",");
                    
                    const canvasFp = getCanvasRawFingerprint()
            
                    // geometry: 도형 렌더링 결과 (toDataURL 문자열)
                    // text: 텍스트 렌더링 결과 (toDataURL 문자열)
                    // 두 값을 "geometry|text" 형식으로 결합하여 하나의 fingerprint 문자열 생성
                    const canvasRaw = canvasFp.geometry + "|" + canvasFp.text
            
                    // 서버 전송 또는 식별자 비교를 위한 최종 문자열 fingerprint 반환
                    return canvasRaw
              }
            
                // Canvas fingerprint를 생성하는 최상위 함수
                // 안티-핑거프린팅 기능이 브라우저에 활성화되어 있는지 판단하고,
                // 해당 여부에 따라 fingerprint 수집을 생략하거나 수행한다.
                function getCanvasRawFingerprint() {
                  return getUnstableCanvasFingerprint(doesBrowserPerformAntifingerprinting())
                }
            
                // 실제로 canvas fingerprint를 생성하는 핵심 함수
                // skipImages가 true인 경우, 보안을 이유로 렌더링을 생략한다.
                function getUnstableCanvasFingerprint(skipImages) {
                  var winding = false // evenodd 채움 방식 지원 여부 (브라우저 구현 특성 측정)
                  var geometry, text  // 도형 기반 fingerprint, 텍스트 기반 fingerprint
            
                  // canvas 요소와 2D 컨텍스트를 생성한다.
                  var result = makeCanvasContext()
                  var canvas = result[0]
                  var context = result[1]
            
                  // 브라우저가 canvas와 context를 제대로 지원하지 않는 경우
                  if (!isSupported(canvas, context)) {
                    geometry = text = 'unsupported'
                  } else {
                    // evenodd 채움 방식 지원 여부를 확인
                    winding = doesSupportWinding(context)
            
                    // 안티핑거프린팅이 켜져 있을 경우 렌더링을 생략
                    if (skipImages) {
                      geometry = text = 'skipped'
                    } else {
                      // 텍스트/도형 렌더링을 통해 fingerprint 이미지 생성
                      var images = renderImages(canvas, context)
                      geometry = images[0] // 도형 기반 fingerprint
                      text = images[1]     // 텍스트 기반 fingerprint
                    }
                  }
            
                  // 최종적으로 각 fingerprint 값을 객체 형태로 반환
                  return { winding: winding, geometry: geometry, text: text }
                }
            
                // canvas 요소와 2D context를 생성
                function makeCanvasContext() {
                  var canvas = document.createElement('canvas')
                  canvas.width = 1
                  canvas.height = 1
                  return [canvas, canvas.getContext('2d')]
                }
            
                // 브라우저가 canvas와 toDataURL 메서드를 지원하는지 확인
                function isSupported(canvas, context) {
                  return !!(context && canvas.toDataURL)
                }
            
                // 브라우저가 evenodd 채움 방식을 지원하는지 테스트
                // 이 기능은 도형 겹침 시 안쪽을 비우는 방식으로, 일부 브라우저는 지원하지 않음
                function doesSupportWinding(context) {
                  // 바깥 사각형
                  context.rect(0, 0, 10, 10)
                  // 안쪽 사각형
                  context.rect(2, 2, 6, 6)
                  // 중심 좌표 (5,5)가 'evenodd' 기준으로 채워졌는지 확인
                  // 지원 시: 비워져야 하므로 false → !false = true
                  // 미지원 시: 채워짐 → true → !true = false
                  return !context.isPointInPath(5, 5, 'evenodd')
                }
            
                // canvas에 텍스트와 도형을 그려 fingerprint 이미지 생성
                function renderImages(canvas, context) {
                  // 텍스트 렌더링 수행
                  renderTextImage(canvas, context)
                  var textImage1 = canvasToString(canvas) // 첫 렌더링
                  var textImage2 = canvasToString(canvas) // 두 번째 렌더링
            
                  // 두 이미지가 서로 다르다면 해당 환경에서는 결과가 불안정하므로 "unstable" 처리
                  if (textImage1 !== textImage2) {
                    return ['unstable', 'unstable']
                  }
            
                  // 도형 기반 렌더링 수행
                  renderGeometryImage(canvas, context)
                  var geometryImage = canvasToString(canvas)
            
                  // geometry: 도형 기반 fingerprint
                  // textImage1: 텍스트 기반 fingerprint
                  return [geometryImage, textImage1]
                }
            
                // 텍스트를 다양한 스타일로 캔버스에 그려 fingerprint를 구성
                function renderTextImage(canvas, context) {
                  // 캔버스 크기 설정 (텍스트 표현에 적절한 크기)
                  canvas.width = 240
                  canvas.height = 60
            
                  // baseline 설정 및 배경색 사각형 그리기
                  context.textBaseline = 'alphabetic'
                  context.fillStyle = '#f60'
                  context.fillRect(100, 1, 62, 20)
            
                  // 첫 번째 텍스트 스타일
                  context.fillStyle = '#069'
                  context.font = '11pt "Times New Roman"'
                  var printedText = 'Cwm fjordbank gly ' + String.fromCharCode(55357, 56835) // 특수 문자: 😃
                  context.fillText(printedText, 2, 15)
            
                  // 두 번째 텍스트 스타일 (다른 폰트, 다른 색상)
                  context.fillStyle = 'rgba(102, 204, 0, 0.2)'
                  context.font = '18pt Arial'
                  context.fillText(printedText, 4, 45)
                }
            
                // 도형을 그려 캔버스의 색상 혼합/렌더링 방식을 테스트
                function renderGeometryImage(canvas, context) {
                  canvas.width = 122
                  canvas.height = 110
            
                  // 색상 혼합 방식을 multiply로 설정
                  context.globalCompositeOperation = 'multiply'
            
                  // 세 개의 반투명 원을 서로 겹쳐서 색상 블렌딩 특성 확인
                  var circles = [
                    ['#f2f', 40, 40], // 보라색
                    ['#2ff', 80, 40], // 하늘색
                    ['#ff2', 60, 80], // 노란색
                  ]
                  for (var i = 0; i < circles.length; i++) {
                    var color = circles[i][0]
                    var x = circles[i][1]
                    var y = circles[i][2]
                    context.fillStyle = color
                    context.beginPath()
                    context.arc(x, y, 40, 0, Math.PI * 2, true)
                    context.closePath()
                    context.fill()
                  }
            
                  // 중심에 큰 원 + 작은 원을 그리고 evenodd 채움 규칙으로 구멍처럼 비워줌
                  context.fillStyle = '#f9c'
                  context.arc(60, 60, 60, 0, Math.PI * 2, true) // 큰 원
                  context.arc(60, 60, 20, 0, Math.PI * 2, true) // 작은 원
                  context.fill('evenodd') // 도형 속 도형 비우기 (지원 시)
                }
            
                // 캔버스를 base64 인코딩된 이미지로 변환
                function canvasToString(canvas) {
                  return canvas.toDataURL()
                }
            
                // 현재 브라우저가 안티-핑거프린팅 기능을 수행하는지 판단
                // 예: Safari Private 모드, Firefox의 보호 기능 등은 fingerprint 수집을 제한할 수 있음
                // 이 예시에서는 Android WebView 등을 고려해 false로 고정
                function doesBrowserPerformAntifingerprinting() {
                  return false // Android WebView는 대체로 fingerprint 차단하지 않음
                }
            
              function getWebGLFingerprint() {
                const canvas = document.createElement("canvas");
                const gl = canvas.getContext("webgl");
                if (!gl) return "webgl-not-supported";
                const debugInfo = gl.getExtension("WEBGL_debug_renderer_info");
                const vendor = debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : "unknown";
                const renderer = debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : "unknown";
                const precision = gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision;
                return `${vendor}|${renderer}|${precision}`;
              }
            
              async function getAudioFingerprint() {
                try {
                    const drift = floatingPointDrift();
                    const freq = 10000 + (drift * 10) % 200; // noise → 주파수에 반영
            
                    const ctx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 44100, 51200);
                    const osc = ctx.createOscillator();
                    osc.type = "triangle";
                    osc.frequency.setValueAtTime(freq, ctx.currentTime);    // noise 반영된 freq
            
                    const comp = ctx.createDynamicsCompressor();
                    comp.threshold.setValueAtTime(-50, ctx.currentTime);
                    comp.knee.setValueAtTime(40, ctx.currentTime);
                    comp.ratio.setValueAtTime(12, ctx.currentTime);
                    comp.attack.setValueAtTime(0, ctx.currentTime);
                    comp.release.setValueAtTime(0.25, ctx.currentTime);
            
                    osc.connect(comp);
                    comp.connect(ctx.destination);
                    osc.start();
            
                    const buffer = await ctx.startRendering();
                    const data = buffer.getChannelData(0);
                    
                    const fingerprint = data.slice(4500, 4600) // 특정 범위만 사용
                      .map(v => v.toFixed(5))
                      .join(",");
            
                    return fingerprint;
                  } catch (e) {
                    return "audio-error";
                  }
              }
            
              function getNavigatorFingerprint() {
                return [
                  navigator.userAgent,
                  navigator.platform,
                  cleanUserAgent(navigator.userAgent),
                  navigator.language,
                  navigator.languages?.join(','),
                  navigator.hardwareConcurrency,
                  screen.width,
                  screen.height,
                  window.devicePixelRatio,
                  new Date().getTimezoneOffset(),
                  Intl.DateTimeFormat().resolvedOptions().timeZone
                ].join("|");
              }
            
              function getRequiredFingerprint() {
                return [
                  navigator.platform,
                  cleanUserAgent(navigator.userAgent),
                  navigator.language,
                  navigator.languages?.join(','),
                  navigator.hardwareConcurrency,
                  screen.width,
                  screen.height,
                  window.devicePixelRatio,
                  new Date().getTimezoneOffset(),
                  Intl.DateTimeFormat().resolvedOptions().timeZone
                ].join("|");
              }
            
              function cleanUserAgent(ua) {
                // 예시: Android, iOS, Windows, Mac만 추출하고 버전 등 세부정보 제거
            
                // Android 부분만 추출
                const androidMatch = ua.match(/Android\\s[\\d\\.]+/);
                if (androidMatch) return androidMatch[0]; // e.g. "Android 10"
            
                // iPhone, iPad, iPod 부분만 추출
                const iosMatch = ua.match(/(iPhone|iPad|iPod);.*OS\\s[\\d_]+/);
                if (iosMatch) {
                  // 예: "iPhone; CPU iPhone OS 14_6" -> "iPhone OS 14.6"
                  return iosMatch[0]
                    .replace(/iPhone;/g, '')
                    .replace(/CPU /g, '')
                    .replace(/_/g, '.')
                    .trim();
                }
            
                // Windows 부분 추출
                const windowsMatch = ua.match(/Windows NT\\s[\\d\\.]+/);
                if (windowsMatch) return windowsMatch[0]; // e.g. "Windows NT 10.0"
            
                // Mac OS X 부분 추출
                const macMatch = ua.match(/Mac OS X\\s[\\d_]+/);
                if (macMatch) {
                  return macMatch[0].replace(/_/g, '.'); // e.g. "Mac OS X 10.15.7"
                }
            
                // 그 외는 원본 UA를 줄이거나 unknown 처리
                return "unknown";
              }
            
                console.log("🧪 generateDeviceFingerprint() 실행 시작");
                try {
                  // const noise = floatingPointDrift();
                  // console.log("🧪 noise() 실행 시작 : " + noise);
                  const nav = getRequiredFingerprint();
                  // console.log("🧪 nav() 실행 시작 : " + nav + "|" + await sha256(nav));
                  
                  const canvas = getCanvasFingerprint();
                  // console.log("🧪 canvas() 실행 시작 : " + await sha256(canvas));
                  const webgl = getWebGLFingerprint();
                  // console.log("🧪 webgl() 실행 시작 : " + await sha256(webgl));
                  const audio = await getAudioFingerprint();
                  // console.log("🧪 audio() 실행 시작 : " + await sha256(audio));
                  // const nav = getNavigatorFingerprint();
                  
                  // const combined = [noise, canvas, webgl, audio, nav].join("||");
                  //const fingerprint = await sha256(combined);
                  //window.webkit.messageHandlers.fingerprintHandler.postMessage("✅ 최종 해시: " + fingerprint);
            
            
                  //const requiredHash = await sha256(nav);
                  //const userAgent = navigator.userAgent;
                  //const canvasHash = await sha256(canvas);
                  //const webglHash = await sha256(webgl);
                  //const audioHash = await sha256(audio);
                  //const combined = [requiredHash, userAgent, canvasHash, webglHash, audioHash].join("||");
                  //window.webkit.messageHandlers.fingerprintHandler.postMessage(combined);
            
                  const requiredHash = sha256(nav);
                  const userAgent = navigator.userAgent;
                  const canvasHash = sha256(canvas);
                  const webglHash = sha256(webgl);
                  const audioHash = await sha256(audio);
                  const combined = [requiredHash, userAgent, canvasHash, webglHash, audioHash].join("||");
                  window.webkit.messageHandlers.fingerprintHandler.postMessage(combined);
                  
                } catch (e) {
                  window.webkit.messageHandlers.fingerprintHandler.postMessage("❌ JS 오류: " + e.message);
                  // return fingerprint;
                }
            }
            
            // 웹뷰가 로드되면 자동 실행
            //document.addEventListener("DOMContentLoaded", function () {
            //console.log("🧪 DOMContentLoaded → generateDeviceFingerprint()");
            //  generateDeviceFingerprint();
            //});
            """
    
    let fingerprintCanvasScript: String = """
        //<script>
        function getCanvasFingerprint() {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext("2d");
        
            // 캔버스에 텍스트와 도형을 그림
            ctx.textBaseline = "top";
            ctx.font = "14px 'Arial'";
            ctx.fillStyle = "#f60";
            ctx.fillRect(0, 0, 100, 50);
            ctx.fillStyle = "#069";
            ctx.fillText("WebGL Fingerprint, 🍇👋", 10, 10);
            // 이미지 데이터 추출
            const dataURL = canvas.toDataURL();
        
            // 간단한 해싱 함수 (SHA-256을 권장)
            //return sha256(dataURL);
        
            // 메시지 전달: JS → Swift
            //window.webkit.messageHandlers.canvasFingerprintHandler.postMessage(dataURL);
        
            const shortFP = dataURL.substring(0, 64); // 앞 64자만 사용
            window.webkit.messageHandlers.canvasFingerprintHandler.postMessage(shortFP);
        }
        
        //window.onload = getCanvasFingerprint();
        //
        // SHA-256 해시 함수 예시 (브라우저에서 사용 가능)
        //async function sha256(message) {
        //    const msgBuffer = new TextEncoder().encode(message);
        //    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
        //    const hashArray = Array.from(new Uint8Array(hashBuffer));
        //    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        //}
        
        // getCanvasFingerprint().then(console.log);
        //</script>
        """
    
    let fingerprintWebGLScript: String = """
        //<script>
        function getWebGLFingerprint() {
          try {
            const canvas = document.createElement('canvas');
            const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            if (!gl) return "no_webgl";
        
            // 간단한 vertex shader
            const vertexShaderSource = `
              attribute vec2 position;
              void main() {
                gl_Position = vec4(position, 0.0, 1.0);
              }
            `;
        
            // 간단한 fragment shader
            const fragmentShaderSource = `
              precision mediump float;
              void main() {
                gl_FragColor = vec4(0.1, 0.2, 0.3, 1.0); // 미세한 색상차 유도
              }
            `;
        
            // 컴파일러 함수
            function compileShader(type, source) {
              const shader = gl.createShader(type);
              gl.shaderSource(shader, source);
              gl.compileShader(shader);
              return shader;
            }
        
            const vertexShader = compileShader(gl.VERTEX_SHADER, vertexShaderSource);
            const fragmentShader = compileShader(gl.FRAGMENT_SHADER, fragmentShaderSource);
        
            const program = gl.createProgram();
            gl.attachShader(program, vertexShader);
            gl.attachShader(program, fragmentShader);
            gl.linkProgram(program);
            gl.useProgram(program);
        
            const vertices = new Float32Array([
              -1, -1,
               1, -1,
              -1,  1,
               1,  1,
            ]);
            const buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
            gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
        
            const position = gl.getAttribLocation(program, 'position');
            gl.enableVertexAttribArray(position);
            gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
        
            gl.clearColor(0.5, 0.5, 0.5, 1.0);
            gl.clear(gl.COLOR_BUFFER_BIT);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        
            // const pixels = new Uint8Array(32 * 32 * 4); // 일부만 읽어도 됨
            // gl.readPixels(0, 0, 32, 32, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
        
            const pixels = new Uint8Array(8 * 8 * 4); // 64픽셀만
            gl.readPixels(0, 0, 8, 8, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
        
            //let hash = 0;
            //for (let i = 0; i < pixels.length; i += 4) {
            //  hash ^= pixels[i]; // 단순 XOR로 요약
            //}
            //
            //return hash.toString(16).padStart(16, '0'); // 짧은 hex string
        
            // 간단한 해시 함수 (SHA-256 등 대체 가능)
            function simpleHash(arr) {
              let hash = 0;
              for (let i = 0; i < arr.length; i++) {
                hash = (hash * 31 + arr[i]) >>> 0;
              }
              return hash.toString(16);
            }
            
            return simpleHash(pixels);
          } catch (e) {
            return "WebGL error";
          }
        }
        
        //console.log("🔍 WebGL Fingerprint:", getWebGLFingerprint());
        //</script>
        """
    
    let fingerprintAudioContextScript: String = """
        //<script>
        //function getAudioFingerprint(callback) {
        function getAudioFingerprint() {
          try {
            const ctx = new (window.OfflineAudioContext || window.webkitOfflineAudioContext)(1, 44100, 44100);
        
            const oscillator = ctx.createOscillator();
            oscillator.type = 'triangle';
            oscillator.frequency.setValueAtTime(10000, ctx.currentTime);
        
            const compressor = ctx.createDynamicsCompressor();
            compressor.threshold.setValueAtTime(-50, ctx.currentTime);
            compressor.knee.setValueAtTime(40, ctx.currentTime);
            compressor.ratio.setValueAtTime(12, ctx.currentTime);
            compressor.attack.setValueAtTime(0, ctx.currentTime);
            compressor.release.setValueAtTime(0.25, ctx.currentTime);
        
            oscillator.connect(compressor);
            compressor.connect(ctx.destination);
            oscillator.start(0);
        
            ctx.startRendering().then(function(buffer) {
              const data = buffer.getChannelData(0); // float32 array
              let sum = 0;
              for (let i = 0; i < data.length; i += 100) { // 일부 샘플만 추출
                sum += Math.abs(data[i]);
              }
              const hash = sum.toString(16); // 예: 간단한 해시 생성
              // callback(hash);
              window.webkit.messageHandlers.audioFingerprintHandler.postMessage(hash);
            });
          } catch (e) {
            // callback("audio-fingerprint-error");
              window.webkit.messageHandlers.audioFingerprintHandler.postMessage("audio-fingerprint-error");
          }
        }
        
        window.console.log = function(message) {
            window.webkit.messageHandlers.audioFingerprintHandler.postMessage(message);
        };
        
        //window.onload = function() {
        //  getAudioFingerprint(function(fingerprint) {
        //    console.log("🎧 AudioContext Fingerprint:", fingerprint);
            // → NativeBridge.onAudioFingerprint(fingerprint) 처럼 앱으로 전달도 가능
        //  });
        //};
        
        //</script>
        """
    
    let fingerprintGPUInfoScript: String = """
        //<script>
        function getGPUInfo() {
          const canvas = document.createElement('canvas');
          const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
          if (!gl) {
            return { error: "WebGL not supported" };
          }
        
          const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
          if (debugInfo) {
            const vendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
            const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
            return { vendor, renderer };
          } else {
            // fallback if extension not available
            return {
              vendor: gl.getParameter(gl.VENDOR),         // Less accurate
              renderer: gl.getParameter(gl.RENDERER)      // May return "WebKit WebGL"
            };
          }
        }
        
        const info = getGPUInfo();
        //document.getElementById('gpu-info').textContent = JSON.stringify(info, null, 2);
        //</script>
        """
    
    let htmlContent: String = "<html><head><meta charset='UTF-8'></head><body></body></html>"
    
    public struct FingerprintResult {
        public var requiredHash: String?
        public var userAgent: String?
        public var canvasHash: String?
        public var webGLHash: String?
        public var audioHash: String?
        
        var isComplete: Bool {
            return requiredHash != nil &&
            userAgent != nil &&
            canvasHash != nil &&
            webGLHash != nil &&
            audioHash != nil
        }
    }
    
    private var fingerprintResult = FingerprintResult()
    private var finalCompletion: ((FingerprintResult) -> Void)?
    
    var webView: WKWebView!
    
    private func checkIfCompleted() {
        if fingerprintResult.isComplete {
            finalCompletion?(fingerprintResult)
        }
    }
    
    
    public func getScriptFingerprint(completion: @escaping (FingerprintResult) -> Void) {
        
        self.finalCompletion = completion
        
        let userScript = WKUserScript(source: fingerprintScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        let contentController = WKUserContentController()
        
        // let debugLogger = """
        //console.log = (msg) => window.webkit.messageHandlers.fingerprintHandler.postMessage("console:" + msg);
        //console.error = (msg) => window.webkit.messageHandlers.fingerprintHandler.postMessage("error:" + msg);
        //"""
        // contentController.addUserScript(WKUserScript(source: debugLogger, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        contentController.addUserScript(userScript)
        contentController.add(self, name: "fingerprintHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        
        // 아주 가벼운 HTML을 로드
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    
    // WKNavigationDelegate Interface
    // 로드가 끝난 뒤 호출
    // iOS: User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
    // AOS: User-Agent: Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.131 Mobile Safari/537.36
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("💻 WebView didFinish!!")
        
        // JS FingerPrint 호출
        webView.evaluateJavaScript("generateDeviceFingerprint();")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        print("💻 didFailProvisionalNavigation!!")
    }
    
    
    // WKScriptMessageHandler Interface
    // ✅ JS → Swift 메시지 처리
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "fingerprintHandler", let fingerprint = message.body as? String {
            print("🔐 받은 Fingerprint: \(fingerprint)")
            
            let values = fingerprint.components(separatedBy: "||")
            for (index, value) in values.enumerated() {
                switch index {
                    case 0:
                        fingerprintResult.requiredHash = value
                    case 1:
                        fingerprintResult.userAgent = value
                    case 2:
                        fingerprintResult.canvasHash = value
                    case 3:
                        fingerprintResult.webGLHash = value
                    case 4:
                        fingerprintResult.audioHash = value
                    default:
                        break
                }
            }
            
            //            checkIfCompleted()
            finalCompletion?(fingerprintResult)
        }
    }
}
