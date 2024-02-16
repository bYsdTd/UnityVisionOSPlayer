using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using AOT;
using UnityEngine;

public class NativeCallback : MonoBehaviour
{
    delegate void CallbackFromObjectC(string message);
    
#if UNITY_VISIONOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    static extern void RegisterNativeCallback(CallbackFromObjectC func);
#else
    static void RegisterNativeCallback(CallbackFromObjectC func)
    {
        
    }
#endif
    [MonoPInvokeCallback(typeof(CallbackFromObjectC))]
    static void CallbackHandler(string message)
    {
        Debug.Log($"Unity: NativeCallback  CallbackHandler {message}");
    }
    
    // Start is called before the first frame update
    void Start()
    {
        RegisterNativeCallback(CallbackHandler);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
