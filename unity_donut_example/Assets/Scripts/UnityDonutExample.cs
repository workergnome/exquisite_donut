using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ExquisiteDonut;

public class UnityDonutExample : MonoBehaviour {
	// Required for OSC Donut
	private List<Sprinkle> sprinkles;
	private List<int> sprinklesToRemove;
	private DonutCop cop;

	// Variables for projecting dots onto plane
	int h;
	int w;
	RaycastHit hit;
	Ray ray;
	private Camera cam;
	// Variables to instantiate and keep track of game objects
	public GameObject dot;
	private GameObject[] dots;
	private List<GameObject> dotsEnabled;
	private List<GameObject> dotsDisabled;
	// Counter for generating random particles
	private int counter;

	// Use this for initialization
	void Start () {
		// Required for OSC Donut
		sprinkles = new List<Sprinkle>();
		sprinklesToRemove = new List<int> ();
		cop = new DonutCop ();
		// Camera params
		cam = Camera.main;
		h = cam.pixelHeight;
		w = cam.pixelWidth;
		// Preallocate game objects for speed
		dotsEnabled = new List<GameObject>();
		dotsDisabled = new List<GameObject>();
		dots = new GameObject[cop.maxSprinkles()];
		for (int i = 0; i < dots.Length; i++) {
			dots [i] = Instantiate(dot);
			dots [i].transform.position.Set (0, 1000, 0);
			dotsDisabled.Add (dots [i]);
		}
		counter = 0;
	}
	
	// Update is called once per frame
	void Update(){
		// Required for OSC Donut
		UpdateSprinkles ();
		// Create random sprinkles for testing
		counter++;
		if (counter % 1 == 0) {
			ProduceRandomSprinkle ();
		}
	}

	// Testing function to initialize random sprinkles
	void ProduceRandomSprinkle(){
		Vector2 pos = new Vector2 (0, Random.value);
		Vector2 vel = new Vector2(Random.Range(0.005f,0.01f),0);
		Vector2 acc = new Vector2(0,0);
		Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
		cop.BroadcastSprinkle(p);
	}

	void UpdateSprinkles(){
		cop.Update (sprinkles.Count);
		// Add new sprinkles from OSC
		while(cop.HasNewSprinkles()){
			Sprinkle p = cop.GetNextSprinkle ();
			if (cop.AllowedToCreateSprinkle (sprinkles.Count)) {
				sprinkles.Add (p);
				int dotsLeft = dotsDisabled.Count;
				if (dotsLeft > 0) {
					EnableDot (dotsLeft - 1);
				}
			}
		}
		// Update sprinkles and their game objects
		for(int i= 0; i<sprinkles.Count; i++){
			Sprinkle p = sprinkles[i];
			// Move sprinkles
			p.Update(cop.maxVelocity(),cop.maxAcceleration());
			// Draw sprinkles
			DrawSprinkle(p, i);
			// Apply physics to sprinkles for next frame
			SprinklePhysics(p);
			// Set to remove and publish sprinkles that are outside screen
			if(p.pos.x > 1 || p.pos.x < 0){
				sprinklesToRemove.Add(i);
			}
		}
		// Sort descending to not screw up our indexing
		sprinklesToRemove.Sort();
		sprinklesToRemove.Reverse();
		// Remove and publish sprinkles set for deletion
		while(sprinklesToRemove.Count>0){
			int idx = sprinklesToRemove[0];
			Sprinkle p = sprinkles[idx];
			dots [idx].transform.position.Set (0, 1000, 0);
			cop.BroadcastSprinkle(p);
			sprinkles.Remove(p);
			sprinklesToRemove.RemoveAt(0);
			DisableDot (idx);
		}
		// Remove overflow sprinkles
		while(sprinkles.Count > cop.maxSprinkles()){
			sprinkles.RemoveAt(0);
		}
	}

	void DrawSprinkle(Sprinkle p, int idx) {
		ray = cam.ScreenPointToRay (new Vector3 (p.pos.x * w, (1-p.pos.y) * h, 0));
		int layerMask = 1 << 8;
		if (Physics.Raycast (ray, out hit, Mathf.Infinity, layerMask)) {
			Debug.DrawLine(ray.origin, hit.point, new Color (0, 1, 0));
			dotsEnabled [idx].transform.position = hit.point;
		}
	}

	void EnableDot(int idx){
		dotsEnabled.Add (dotsDisabled [idx]);
		dotsDisabled [idx].SetActive (true);
		dotsDisabled.RemoveAt (idx);
	}

	void DisableDot(int idx){
		dotsDisabled.Add (dotsEnabled [idx]);
		dotsEnabled [idx].SetActive (false);
		dotsEnabled.RemoveAt (idx);
	}

	void SprinklePhysics(Sprinkle p) {
		// Reverse velocity if position is out of bounds
		if(p.pos.y<0){
			p.vel.y = Mathf.Abs(p.vel.y);
		}
		else if(p.pos.y>1){
			p.vel.y = Mathf.Abs(p.vel.y)*-1;
		}
		else{
			p.acc.y = .0002f;   
		}
	}
}
