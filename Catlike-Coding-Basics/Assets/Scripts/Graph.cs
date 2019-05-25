using UnityEngine;

public class Graph : MonoBehaviour {

	public Transform pointPrefab;

	[Range(10, 100)]
	public int resolution = 10;

	public GraphFunctionName function;
	static GraphFunction[] functions = {
		SineFunction, Sine2DFunction, MultiSineFunction, MultiSine2DFunction, Ripple, Cylinder, Sphere
	};

	Transform[] points;

	void Awake () {
		float step = 2f / resolution;
		Vector3 scale = Vector3.one * step;
		points = new Transform[resolution * resolution];
		for(int i = 0; i < points.Length; i++) {
			Transform point = Instantiate(pointPrefab);
			point.localScale = scale;
			point.SetParent(transform, false);
			points[i] = point;
		}
	}

	void Update () {
		float t = Time.time;
		GraphFunction f = functions[(int) function];
		float step = 2f / resolution;
		for(int i = 0, z = 0; z < resolution; z++) {
			float v = (z + 0.5f) * step - 1f;
			for(int x = 0; x < resolution; x++, i++) {
				float u = (x + 0.5f) * step - 1f;
				points[i].localPosition = f(u, v, t);
			}
		}
	}

	const float PI = Mathf.PI;
	static Vector3 SineFunction(float x, float z, float t) {
		Vector3 p;
		p.x = x;
		p.y = Mathf.Sin(PI * (x +t));
		p.z = z;
		return p;
	}

	static Vector3 Sine2DFunction(float x, float z, float t) {
		Vector3 p;
		p.x = x;
		p.y = Mathf.Sin(PI * (x + t));
		p.y += Mathf.Sin(PI * (z + t));
		p.y *= 0.5f;
		p.z = z;
		return p;
	}

	static Vector3 MultiSineFunction(float x, float z, float t) {
		Vector3 p;
		p.x = x;
		p.y = Mathf.Sin(PI * (x + t));
		p.y += Mathf.Sin(2f * PI * (x + 2f * t)) / 2f;
		p.y *= 2f / 3f;
		p.z = z;
		return p;
	}

	static Vector3 MultiSine2DFunction(float x, float z, float t) {
		Vector3 p;
		p.x = x;
		p.y = 4f * Mathf.Sin(PI * (x + z + t * 0.5f));
		p.y += Mathf.Sin(PI * (x + t));
		p.y += Mathf.Sin(2f * PI * (x + 2f * t)) * 0.5f;
		p.y *= 1f / 5.5f;
		p.z = z;
		return p;
	}

	static Vector3 Ripple (float x, float z, float t) {
		Vector3 p;
		p.x = x;
		float d = Mathf.Sqrt(x * x + z * z);
		p.y = Mathf.Sin(PI * (4f * d - t));
		p.y /= 1f + 10f * d;
		p.z = z;
		return p;
	}

	static Vector3 Cylinder(float u, float v, float t) {
		Vector3 p;
		float r = 0.8f + Mathf.Sin(PI * (6f * u + 2f * v + t)) * 0.2f;
		p.x = r * Mathf.Sin(PI * u);
		p.y = v;
		p.z = r * Mathf.Cos(PI * u);
		return p;
	}

	static Vector3 Sphere(float u, float v, float t) {
		Vector3 p;
		float r = Mathf.Cos(PI * 0.5f * v);
		p.x = r * Mathf.Sin(PI * u);
		p.y = Mathf.Sin(PI * 0.5f * v);
		p.z = r * Mathf.Cos(PI * u);
		return p;
	}
}