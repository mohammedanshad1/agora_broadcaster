**Task: Implement Live Streaming with Agora + Cross-Platform Restreaming**

**Assigned to:** Flutter Developer

**Objective:**
Implement live streaming in the Flutter app using **Agora**, with support for broadcasting the same live stream to other social media platforms.

**Requirements:**

1. Integrate **Agora Live Streaming SDK** in Flutter.
2. Create live stream flow for:

   * Host going live
   * Audience joining live
   * Host ending live
3. Add support for **RTMP / CDN push** so the live stream can be broadcasted to platforms like:

   * YouTube Live
   * Facebook Live
   * Instagram Live, if supported via streaming endpoint
   * Other platforms with RTMP URL and stream key
4. Allow admin/host to enter or configure:

   * RTMP server URL
   * Stream key
   * Platform name
5. Start cross-live streaming when host starts the Agora live session.
6. Stop RTMP streaming when host ends the live session.
7. Handle errors for:

   * Invalid stream URL/key
   * Agora connection failure
   * RTMP push failure
8. Show live status clearly:

   * Live started
   * Cross-live connected
   * Cross-live failed
   * Live ended

**Expected Output:**
A working Flutter implementation where a host can go live using Agora and stream the same live session to supported external social media platforms using RTMP/CDN push.