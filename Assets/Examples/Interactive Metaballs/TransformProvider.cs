using UnityEngine;

[ExecuteInEditMode]
public class TransformProvider : MonoBehaviour
{
    [System.Serializable]
    public class NameTransformPair
    {
        public string name;
        public Transform transform;
    }

    [SerializeField]
    NameTransformPair[] pairs;

    void Update()
    {
        var renderer = GetComponent<Renderer>();
        if (!renderer) return;

        var material = renderer.sharedMaterial;
        if (!material) return;

        foreach (var pair in pairs)
        {
            var pos = pair.transform.position;
            var rot = pair.transform.rotation;
            var mat = Matrix4x4.TRS(pos, rot, Vector3.one);
            var invMat = Matrix4x4.Inverse(mat);
            material.SetMatrix(pair.name, invMat);
        }
    }
}
