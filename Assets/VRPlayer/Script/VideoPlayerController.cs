using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using AOT;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class VideoPlayerController : MonoBehaviour
{
    delegate void OnPlayerInitCallback(string message, int width, int height);

    delegate void OnExternalTextureChanged(int width, int height, IntPtr metalTexture);

    delegate void OnNormalTextureBufferUpdate(int width, int height, IntPtr buffer, int size);
    
    [SerializeField] private string videoUrl;
    
    [SerializeField] bool isExternal = false;

#if UNITY_VISIONOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void _PlayVideoWithURL(string url, OnPlayerInitCallback cb);

    [DllImport("__Internal")]
    private static extern System.IntPtr GetTextureForCurrentFrame();
    
    [DllImport("__Internal")]
    private static extern void TryCopyPixelBufferToUnity();

    [DllImport("__Internal")]
    private static extern void RegisterNormalTextureUpdate(OnNormalTextureBufferUpdate normalUpdateCallback);
    
    [DllImport("__Internal")]
    private static extern void RegisterExternalTextureUpdate(OnExternalTextureChanged externalTextureCallback);
#else

    private static void _PlayVideoWithURL(string url, OnPlayerInitCallback cb)
    {
        Debug.Log("Unity: Mock _PlayVideoWithURL");
    }
    
    private static System.IntPtr GetTextureForCurrentFrame()
    {
        Debug.Log("Unity: Mock GetTextureForCurrentFrame");
        return IntPtr.Zero;
    }

    private static void TryCopyPixelBufferToUnity()
    {
        Debug.Log("Unity: Mock TryCopyPixelBufferToUnity");
    }

    private static void RegisterNormalTextureUpdate(OnNormalTextureBufferUpdate normalUpdateCallback)
    {
        Debug.Log("Unity: Mock RegisterNormalTextureUpdate");
    }

    private static void RegisterExternalTextureUpdate(OnExternalTextureChanged externalTextureCallback)
    {
        Debug.Log("Unity: Mock RegisterExternalTextureUpdate");
    }
#endif


    private Material _matPlayer;
    private Texture2D _externalTexture;
    private RenderTexture _renderTexture;
    private Texture2D _unityTexture;
    
    private IntPtr _metalTexture;
    private int _texWidth;
    private int _texHeight;
    
    private static VideoPlayerController _instance;
    public void PlayVideo(string url) {
        Debug.Log($"Unity: playVideo {url}");
        RegisterNormalTextureUpdate(OnNormalTexUpdate);
        RegisterExternalTextureUpdate(OnExternalTextureUpdate);
        _PlayVideoWithURL(url, OnPlayerStarted);
    }

    private void Awake()
    {
        _instance = this;
    }

    private void Start()
    {
        var renderer = GetComponent<MeshRenderer>();
        var m = new List<Material>();
        renderer.GetSharedMaterials(m);
        if (m.Count > 0)
        {
            _matPlayer = m[0];
        }
        PlayVideo(videoUrl);
    }

    [MonoPInvokeCallback(typeof(OnPlayerInitCallback))]
    static void OnPlayerStarted(string message, int width, int height)
    {
        Debug.Log($"Unity: OnPlayerStarted {message} width {width} height {height}");
        // if (_instance._matPlayer)
        // {
        //     _instance._externalTexture = Texture2D.CreateExternalTexture(width, height, TextureFormat.RGBA32, false, false, IntPtr.Zero);
        //     _instance._matPlayer.SetTexture("_mainTexture", _instance._externalTexture);
        //     Debug.Log($"Unity: CreateExternalTexture and Set tex: {_instance._externalTexture}");
        //
        // }
    }

    [MonoPInvokeCallback(typeof(OnExternalTextureChanged))]
    static void OnExternalTextureUpdate(int width, int height, IntPtr metalTexture)
    {
        Debug.Log($"Unity: OnExternalTextureUpdate width {width} height {height} metalTexture {metalTexture} instanceWidth {_instance._texWidth} instanceHeight: {_instance._texHeight}");
        if (width != _instance._texWidth || height != _instance._texHeight || metalTexture != _instance._metalTexture)
        {
            _instance._texWidth = width;
            _instance._texHeight = height;
            _instance._metalTexture = metalTexture;
            
            if (metalTexture != IntPtr.Zero)
            {
                if (_instance._externalTexture == null)
                {
                    _instance._externalTexture = Texture2D.CreateExternalTexture(width, height, TextureFormat.BGRA32, false, false, metalTexture);
                    _instance._externalTexture.name = $"ExternalTexture-Metal-{metalTexture}-{width}-{height}";
                    _instance._renderTexture = new RenderTexture(width, height, 0, GraphicsFormat.B8G8R8A8_SRGB);
                    _instance._renderTexture.name = $"RenderTexture-Metal-{width}-{height}";
                    Graphics.CopyTexture(_instance._externalTexture, _instance._renderTexture);
                    
                    Debug.Log($"Unity: CreateExternalTexture and Set tex: {_instance._externalTexture}");
                    if ( _instance._matPlayer)
                    {
                        Debug.Log("Unity: material set texture");
                        _instance._matPlayer.SetTexture("_mainTexture", _instance._renderTexture); 
                    }
                }
                else
                {
                    Debug.Log($"Unity: UpdateExternalTexture tex2D: {_instance._externalTexture} metal tex: {metalTexture}");
                    _instance._externalTexture.UpdateExternalTexture(metalTexture);
                    Graphics.CopyTexture(_instance._externalTexture, _instance._renderTexture);
                }

                if (_instance._renderTexture)
                {
                    Unity.PolySpatial.PolySpatialObjectUtils.MarkDirty(_instance._renderTexture);    
                }
            }
            else
            {
                // 应该不存在，null的话，不会回调
                Debug.LogError("Unity: OnTextureSizeChanged metal texture null!");
            }
        }
    }

    [MonoPInvokeCallback(typeof(OnNormalTextureBufferUpdate))]
    static void OnNormalTexUpdate(int width, int height, IntPtr buffer, int size)
    {
        Debug.Log($"Unity: width {width} height {height} buffer {buffer} size {size}");
        if (width != _instance._texWidth || height != _instance._texHeight || _instance._unityTexture == null)
        {
            _instance._texWidth = width;
            _instance._texHeight = height;

            if (_instance._unityTexture == null)
            {
                _instance._unityTexture = new Texture2D(width, height, TextureFormat.BGRA32, false, false);
                _instance._unityTexture.name = $"UnityTexture-{width}-{height}";
            
                Debug.Log($"Unity: CreateNormalTexture and Set tex: {_instance._unityTexture}");
                if ( _instance._matPlayer)
                {
                    Debug.Log("Unity: material set texture");
                    _instance._matPlayer.SetTexture("_mainTexture", _instance._unityTexture); 
                }
                else
                {
                    // do nothing, copy in update
                }
            }
        }
        
        if (_instance._unityTexture)
        {
            _instance._unityTexture.LoadRawTextureData(buffer, size);
            _instance._unityTexture.Apply();
        }
    }
    
    private void Update()
    {
        if (isExternal)
        {
            IntPtr texturePtr = GetTextureForCurrentFrame();    
            Debug.Log($"Unity: GetTextureForCurrentFrame texturePtr {texturePtr} _externalTexture {_externalTexture}");
        }
        else
        {
            TryCopyPixelBufferToUnity();
        }
        
        //
        // if (texturePtr != IntPtr.Zero && _externalTexture) {
        //     // Debug.Log("Unity: UpdateExternalTexture ");
        //     _externalTexture.UpdateExternalTexture(texturePtr);
        // }
    }
}