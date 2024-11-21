// Pcx - Point cloud importer & renderer for Unity
// https://github.com/keijiro/Pcx

using UnityEngine;
using UnityEditor;

namespace Pcx
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(PointCloudRenderer))]
    public class PointCloudRendererInspector : Editor
    {
        SerializedProperty _pointShader;
        SerializedProperty forceUsePointShader;
        SerializedProperty _sourceData;
        SerializedProperty _pointTint;
        SerializedProperty _pointSize;
        SerializedProperty customPointMaterial;

        void OnEnable()
        {
            _pointShader = serializedObject.FindProperty("_pointShader");
            forceUsePointShader = serializedObject.FindProperty("forceUsePointShader");
            customPointMaterial = serializedObject.FindProperty("customPointMaterial");
            _sourceData = serializedObject.FindProperty("_sourceData");
            _pointTint = serializedObject.FindProperty("_pointTint");
            _pointSize = serializedObject.FindProperty("_pointSize");
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.PropertyField(_pointShader);
            EditorGUILayout.PropertyField(forceUsePointShader);
            EditorGUILayout.PropertyField(customPointMaterial);
            EditorGUILayout.PropertyField(_sourceData);
            EditorGUILayout.PropertyField(_pointTint);
            EditorGUILayout.PropertyField(_pointSize);

            serializedObject.ApplyModifiedProperties();
        }
    }
}
