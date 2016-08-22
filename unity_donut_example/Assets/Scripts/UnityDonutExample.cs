using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ExquisiteDonut;

[RequireComponent (typeof (Osc))]
[RequireComponent (typeof (UDPPacketIO))]

public class UnityDonutExample : MonoBehaviour {
	// Required for OSC Donut
	private DonutCop cop;
	private SprinkleManager sprinkles;

	// Variables for projecting dots onto plane
	int w;
	RaycastHit hit;
	Ray ray;
	private Camera cam;

	// Variables to instantiate and keep track of game objects
	public GameObject dot;
	private GameObject[] dots;

	// Counter for generating random particles
	private int counter;
	private Osc osc;
	private float maxY;

	public int numSprinkles;

	void Awake() {
		// Camera params
		cam = Camera.main;
		w = cam.pixelWidth;

		// Game settings
		QualitySettings.vSyncCount = 0;
		Application.targetFrameRate = -1;
		float targetFramerate = 60;
		Time.fixedDeltaTime = 1F / targetFramerate;
		maxY = (float)cam.pixelHeight / cam.pixelWidth;

	}
		
	// Use this for initialization
	void Start () {
		// Required for OSC Donut
		sprinkles = new SprinkleManager ();
		string RemoteIP = "10.0.0.255"; //127.0.0.1 signifies a local host (if testing locally
		int SendToPort = 9000; //the port you will be sending from
		int ListenerPort = 9000; //the port you will be listening on
		UDPPacketIO udp = GetComponent<UDPPacketIO>();
		udp.init(RemoteIP, SendToPort, ListenerPort);
		osc = GetComponent<Osc>();
		osc.init(udp);
		cop = new DonutCop (osc);


		// Preallocate game objects for speed
		dots = new GameObject[cop.maxSprinkles()];
		for (int i = 0; i < dots.Length; i++) {
			dots [i] = Instantiate(dot);
			dots [i].transform.position.Set (0, 1000, 0);
		}

		// Counter for generating random sprinkles
		counter = 0;

	}

	// FixedUpdate is called at a constant framerate set above
	void FixedUpdate(){
		// Delete sprinkles set for removal
		sprinkles.ClearRemoved ();
		// Required for OSC Donut
		cop.Update (sprinkles.Count);
		// Add new sprinkles from OSC
		while(cop.HasNewSprinkles()){
			Sprinkle p = cop.GetNextSprinkle ();
			sprinkles.Add (p);
		}

		// Make random sprinkles
		if (counter % 60 == 0) {
			ProduceRandomSprinkle ();
		}
		counter++;

		// Check if sprinkle is out of bounds or malformed from a bad message
		for (int i = 0;  i < sprinkles.Count; i++) {
			Sprinkle p = sprinkles [i];
			try{
				if(p.pos.x > 1 || p.pos.x < 0){
					sprinkles.Remove(p);
					cop.BroadcastSprinkle (p);
				}
				p.Update(cop.maxVelocity(),cop.maxAcceleration());
				SprinklePhysics(p);
			}
			catch{
				sprinkles.Remove (p);
				Debug.Log ("Caught malformed sprinkle at" + i);
			}
		}
		// Iterate through all sprinkles
		int sprinkleIdx = 0;
		// Enable and draw all the dots that have sprinkles attached
		while (sprinkleIdx < dots.Length && sprinkleIdx < sprinkles.Count) {
			Sprinkle p = sprinkles [sprinkleIdx];
			dots[sprinkleIdx].SetActive (true);
			DrawSprinkle (p, sprinkleIdx);
			sprinkleIdx++;
		}
		// Disable and hide all the dots that there are no sprinkles for
		while (sprinkleIdx < dots.Length) {
			dots[sprinkleIdx].SetActive (false);
			sprinkleIdx++;
		}

		// Change public variable for editor window
		numSprinkles = sprinkles.Count;
	}
	
	// Update is called once per frame. You can use this for things that don't have to be 60fps
	void Update(){
		// Fix resizing issues in editor
		w = cam.pixelWidth;
		maxY = (float)cam.pixelHeight / cam.pixelWidth;
	}

	// Testing function to initialize random sprinkles
	void ProduceRandomSprinkle(){
		Vector2 pos = new Vector2 (0, Random.value*maxY);
		Vector2 vel = new Vector2 (cop.maxVelocity()/2, 0);//Random.Range(0.005f,0.01f),0);
		Vector2 acc = new Vector2(0,0);
		Sprinkle p = new Sprinkle(pos,vel,acc, 0, 0);
		if (cop.AllowedToCreateSprinkle(sprinkles.Count)){
			sprinkles.Add (p);
			cop.MentionNewSprinkle ();
		}
	}

	void DrawSprinkle(Sprinkle p, int idx) {
		ray = cam.ScreenPointToRay (new Vector3 (p.pos.x * w, (maxY-p.pos.y) * w, 0));
		int layerMask = 1 << 8;
		if (Physics.Raycast (ray, out hit, Mathf.Infinity, layerMask)) {
			Debug.DrawLine(ray.origin, hit.point, new Color (0, 1, 0));
			dots[idx].transform.position = hit.point;
		}
	}

	void EnableDot(int idx){
		dots[idx].SetActive (true);
	}

	void DisableDot(int idx){
		dots[idx].SetActive (true);
	}

	void SprinklePhysics(Sprinkle p) {
		// Reverse velocity if position is out of bounds
		if(p.pos.y<0){
			p.vel.y = Mathf.Abs(p.vel.y);
		}
		else if(p.pos.y>maxY){
			p.vel.y = Mathf.Abs(p.vel.y)*-1;
		}
		else{
			p.acc.y = .0002f;   
		}
	}
}
