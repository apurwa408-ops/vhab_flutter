/**
 * V-Hab MediaPipe Hands Camera Bridge
 * Contactless Computer Vision Hand Tracking for Physical Rehabilitation
 */

(function () {
  let videoElement = null;
  let canvasElement = null;
  let canvasCtx = null;
  let cameraInstance = null;
  let handsInstance = null;
  let isRunning = false;

  // Rolling position buffer for stability variance computation
  const posHistory = [];
  const MAX_HISTORY = 15;
  let lastProcessTime = 0;
  const PROCESS_INTERVAL_MS = 33; // Up to 30fps, with an in-flight guard below
  let isProcessingFrame = false;

  function initCameraElements() {
    if (!videoElement) {
      videoElement = document.createElement('video');
      videoElement.id = 'vhab-webcam-feed';
      videoElement.autoplay = true;
      videoElement.playsInline = true;
      videoElement.muted = true;
      videoElement.style.position = 'fixed';
      videoElement.style.bottom = '20px';
      videoElement.style.right = '20px';
      videoElement.style.width = '200px';
      videoElement.style.height = '150px';
      videoElement.style.borderRadius = '16px';
      videoElement.style.border = '2px solid #06B6D4';
      videoElement.style.boxShadow = '0 8px 24px rgba(0,0,0,0.4)';
      videoElement.style.zIndex = '9999';
      videoElement.style.objectFit = 'cover';
      videoElement.style.transform = 'scaleX(-1)'; // Mirror preview
      videoElement.style.display = 'none'; // Controlled by Flutter PiP toggle
      document.body.appendChild(videoElement);
    }

    if (!canvasElement) {
      canvasElement = document.createElement('canvas');
      canvasElement.id = 'vhab-skeleton-canvas';
      canvasElement.width = 640;
      canvasElement.height = 480;
      canvasElement.style.position = 'fixed';
      canvasElement.style.bottom = '20px';
      canvasElement.style.right = '20px';
      canvasElement.style.width = '200px';
      canvasElement.style.height = '150px';
      canvasElement.style.pointerEvents = 'none';
      canvasElement.style.zIndex = '10000';
      canvasElement.style.display = 'none';
      document.body.appendChild(canvasElement);
      canvasCtx = canvasElement.getContext('2d');
    }
  }

  function computeDistance(p1, p2) {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = (p1.z || 0) - (p2.z || 0);
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  function classifyGesture(landmarks) {
    // 0: Wrist, 4: Thumb, 8: Index, 12: Middle, 16: Ring, 20: Pinky
    // MCP joints: 2: Thumb MCP, 5: Index MCP, 9: Middle MCP, 13: Ring MCP, 17: Pinky MCP
    const thumbTip = landmarks[4];
    const indexTip = landmarks[8];
    const middleTip = landmarks[12];
    const ringTip = landmarks[16];
    const pinkyTip = landmarks[20];
    const wrist = landmarks[0];

    const pinchDist = computeDistance(thumbTip, indexTip);
    if (pinchDist < 0.075) {
      return 'pinch';
    }

    // Check finger extensions (tip is higher than PIP/MCP)
    const indexExtended = indexTip.y < landmarks[6].y;
    const middleExtended = middleTip.y < landmarks[10].y;
    const ringExtended = ringTip.y < landmarks[14].y;
    const pinkyExtended = pinkyTip.y < landmarks[18].y;
    const thumbUp = thumbTip.y < landmarks[2].y && thumbTip.y < indexTip.y;

    // 1. Thumbs up: thumb extended upward, other 4 curled
    if (thumbUp && !indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return 'thumbs_up';
    }

    // 2. Peace / V-sign: index and middle extended, ring and pinky curled
    if (indexExtended && middleExtended && !ringExtended && !pinkyExtended) {
      return 'peace';
    }

    // 3. Point: index extended, others curled
    if (indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return 'point';
    }

    // 4. Open Palm: all 4 fingers extended
    if (indexExtended && middleExtended && ringExtended && pinkyExtended) {
      return 'open_hand';
    }

    // 5. Fist: all 4 fingers curled
    if (!indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return 'fist';
    }

    return 'open_hand';
  }

  function computeStability(pos) {
    posHistory.push(pos);
    if (posHistory.length > MAX_HISTORY) {
      posHistory.shift();
    }
    if (posHistory.length < 3) return 92.0;

    let deltaSum = 0;
    for (let i = 1; i < posHistory.length; i++) {
      const p1 = posHistory[i - 1];
      const p2 = posHistory[i];
      const d = Math.hypot(p2.x - p1.x, p2.y - p1.y);
      deltaSum += d;
    }
    const avgDelta = deltaSum / (posHistory.length - 1);
    const score = Math.max(30.0, Math.min(99.0, 100.0 - (avgDelta * 900.0)));
    return parseFloat(score.toFixed(1));
  }

  function drawSkeleton(landmarks) {
    if (!canvasCtx) return;
    canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);

    // Skeleton bone connections
    const connections = [
      [0, 1], [1, 2], [2, 3], [3, 4],       // Thumb
      [0, 5], [5, 6], [6, 7], [7, 8],       // Index
      [0, 9], [9, 10], [10, 11], [11, 12],  // Middle
      [0, 13], [13, 14], [14, 15], [15, 16],// Ring
      [0, 17], [17, 18], [18, 19], [19, 20],// Pinky
      [5, 9], [9, 13], [13, 17]             // Palm arch
    ];

    canvasCtx.lineWidth = 3;
    canvasCtx.strokeStyle = '#06B6D4'; // Cyan glowing bones

    connections.forEach(([i, j]) => {
      const p1 = landmarks[i];
      const p2 = landmarks[j];
      // Mirror X for display
      const x1 = (1.0 - p1.x) * canvasElement.width;
      const y1 = p1.y * canvasElement.height;
      const x2 = (1.0 - p2.x) * canvasElement.width;
      const y2 = p2.y * canvasElement.height;

      canvasCtx.beginPath();
      canvasCtx.moveTo(x1, y1);
      canvasCtx.lineTo(x2, y2);
      canvasCtx.stroke();
    });

    // Draw landmark joints
    landmarks.forEach((pt, index) => {
      const x = (1.0 - pt.x) * canvasElement.width;
      const y = pt.y * canvasElement.height;

      canvasCtx.beginPath();
      canvasCtx.arc(x, y, (index === 4 || index === 8) ? 6 : 4, 0, 2 * Math.PI);
      canvasCtx.fillStyle = (index === 4 || index === 8) ? '#7C3AED' : '#22C55E';
      canvasCtx.fill();
    });
  }

  function onResults(results) {
    if (!results.multiHandLandmarks || results.multiHandLandmarks.length === 0) {
      if (canvasCtx) {
        canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
      }
      if (window.vhabOnPoseUpdate) {
        window.vhabOnPoseUpdate(JSON.stringify({ isHandDetected: false }));
      }
      window.dispatchEvent(new CustomEvent('vhab_hand_pose', {
        detail: { isHandDetected: false }
      }));
      return;
    }

    const landmarks = results.multiHandLandmarks[0];
    const indexTip = landmarks[8];
    const thumbTip = landmarks[4];

    // Compute pointer coordinate (Index tip or mid-pinch, mirrored on X)
    const rawX = (indexTip.x + thumbTip.x) / 2.0;
    const rawY = (indexTip.y + thumbTip.y) / 2.0;
    const screenX = Math.max(0.0, Math.min(1.0, 1.0 - rawX));
    const screenY = Math.max(0.0, Math.min(1.0, rawY));

    // Pinch distance
    const pinchDist = computeDistance(thumbTip, indexTip);
    const isPinching = pinchDist < 0.10;
    const pinchStrength = Math.max(0.0, Math.min(1.0, 1.0 - (pinchDist / 0.14)));

    // Grip strength
    const wrist = landmarks[0];
    const avgFingertipDist = (
      computeDistance(landmarks[8], wrist) +
      computeDistance(landmarks[12], wrist) +
      computeDistance(landmarks[16], wrist) +
      computeDistance(landmarks[20], wrist)
    ) / 4.0;
    const gripStrength = Math.max(0.0, Math.min(1.0, 1.0 - (avgFingertipDist / 0.45)));

    // Gesture
    const gesture = classifyGesture(landmarks);
    const stability = computeStability({ x: screenX, y: screenY });

    // Draw visual feedback onto PiP skeleton canvas
    drawSkeleton(landmarks);

    const payload = {
      isHandDetected: true,
      x: screenX,
      y: screenY,
      isPinching: isPinching,
      pinchStrength: parseFloat(pinchStrength.toFixed(2)),
      gripStrength: parseFloat(gripStrength.toFixed(2)),
      gesture: gesture,
      stability: stability,
      pinchDistance: parseFloat(pinchDist.toFixed(3)),
      landmarks: landmarks.map(l => ({ x: 1.0 - l.x, y: l.y, z: l.z }))
    };

    if (window.vhabOnPoseUpdate) {
      window.vhabOnPoseUpdate(JSON.stringify(payload));
    }

    // Send high-speed telemetry event to Flutter
    window.dispatchEvent(new CustomEvent('vhab_hand_pose', {
      detail: payload
    }));
  }

  // Public API exposed to window and Flutter
  window.vhabHandTracker = {
    start: async function () {
      if (isRunning) return true;
      initCameraElements();

      try {
        if (!window.Hands) {
          console.error('[V-Hab] MediaPipe Hands library not loaded');
          return false;
        }

        handsInstance = new window.Hands({
          locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`
        });

        handsInstance.setOptions({
          maxNumHands: 1,
          modelComplexity: 0,
          minDetectionConfidence: 0.5,
          minTrackingConfidence: 0.5
        });

        handsInstance.onResults(onResults);

        if (window.Camera) {
          cameraInstance = new window.Camera(videoElement, {
            onFrame: async () => {
              const now = Date.now();
              if (!isRunning || isProcessingFrame || now - lastProcessTime < PROCESS_INTERVAL_MS) return;
              lastProcessTime = now;
              isProcessingFrame = true;
              if (videoElement && handsInstance) {
                try {
                  await handsInstance.send({ image: videoElement });
                } finally {
                  isProcessingFrame = false;
                }
              }
            },
            width: 640,
            height: 480
          });
          await cameraInstance.start();
        } else {
          // Direct fallback to getUserMedia
          const stream = await navigator.mediaDevices.getUserMedia({
            video: { width: 640, height: 480, facingMode: 'user' }
          });
          videoElement.srcObject = stream;
          await videoElement.play();

          async function processFrame() {
            if (!isRunning) return;
            const now = Date.now();
            if (videoElement.readyState >= 2 && !isProcessingFrame && now - lastProcessTime >= PROCESS_INTERVAL_MS) {
              lastProcessTime = now;
              isProcessingFrame = true;
              try {
                await handsInstance.send({ image: videoElement });
              } finally {
                isProcessingFrame = false;
              }
            }
            requestAnimationFrame(processFrame);
          }
          requestAnimationFrame(processFrame);
        }

        isRunning = true;
        console.log('[V-Hab] Webcam hand tracking initialized successfully.');
        return true;
      } catch (err) {
        console.error('[V-Hab] Failed to initialize camera hand tracking:', err);
        return false;
      }
    },

    stop: function () {
      isRunning = false;
      if (cameraInstance) {
        cameraInstance.stop();
        cameraInstance = null;
      }
      if (videoElement && videoElement.srcObject) {
        const tracks = videoElement.srcObject.getTracks();
        tracks.forEach(track => track.stop());
        videoElement.srcObject = null;
      }
      if (videoElement) {
        videoElement.style.display = 'none';
      }
      if (canvasElement) {
        canvasElement.style.display = 'none';
        if (canvasCtx) {
          canvasCtx.clearRect(0, 0, canvasElement.width, canvasElement.height);
        }
      }
      console.log('[V-Hab] Webcam hand tracking stopped.');
    },

    setPipVisible: function (visible) {
      if (videoElement) videoElement.style.display = visible ? 'block' : 'none';
      if (canvasElement) canvasElement.style.display = visible ? 'block' : 'none';
    },

    isRunning: function () {
      return isRunning;
    }
  };
})();
