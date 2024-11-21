using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteAlways]
public class GeometryPointCloudController : MonoBehaviour
{
    [SerializeField] Shader _pointShader = null;

    Material _pointMaterial;

    void Update()
    {
        if (_pointMaterial == null)
        {
            _pointMaterial = new Material(_pointShader);
            _pointMaterial.hideFlags = HideFlags.DontSave;
        }

        var view = SceneView.currentDrawingSceneView;

        Camera cam = Camera.main;
        if (view != null) { cam = view.camera; }
        var direction = (transform.position - cam.transform.position).normalized;
        var up = Vector3.up;
        var right = Vector3.Cross(direction, up);

        _pointMaterial.SetVector("_BillboardDirection", direction);
        _pointMaterial.SetVector("_BillboardUp", up);
        _pointMaterial.SetVector("_BillboardRight", right);
    }
}
