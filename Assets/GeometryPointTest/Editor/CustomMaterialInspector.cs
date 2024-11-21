
using UnityEditor;

class GeometryPointPointMaterialInspector : ShaderGUI
{
    public override void OnGUI(MaterialEditor editor, MaterialProperty[] props)
    {
        editor.ShaderProperty(FindProperty("_MainTex", props), "Texture");
        editor.ShaderProperty(FindProperty("_Tint", props), "Tint");
        editor.ShaderProperty(FindProperty("_PointSize", props), "Point Size");
        editor.ShaderProperty(FindProperty("_Cutoff", props), "Cutoff");
        editor.ShaderProperty(FindProperty("_MipScale", props), "Mip Scale");
        editor.ShaderProperty(FindProperty("_Distance", props), "Apply Distance");
    }
}