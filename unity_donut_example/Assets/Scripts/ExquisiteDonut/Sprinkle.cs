using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System; //This allows the IComparable Interface
using UnityOSC;

namespace ExquisiteDonut
{
	public class Sprinkle{
		
		public Vector2 pos;
		public Vector2 vel;
		public Vector2 acc;
		public float free1;
		public float free2;

		public Sprinkle(Vector2 _pos, Vector2 _vel, Vector2 _acc,
						float _free1, float _free2){
			pos = _pos;
			vel = _vel;
			acc = _acc;
			free1 = _free1;
			free2 = _free2;
		}

		public void Update(float maxVel, float maxAcc) {
			acc = Vector2.ClampMagnitude (acc, maxAcc);
			vel = Vector2.ClampMagnitude (vel, maxVel);
			pos = pos + vel;
			vel = vel + acc;
		}

		public ArrayList CreateOSCData() {
			ArrayList m = new ArrayList();
			m.Add(pos.y);
			m.Add(vel.x);
			m.Add(vel.y);
			m.Add(acc.x);
			m.Add(acc.y);
			m.Add(free1);
			m.Add(free2);
			return m;
		}
	}
}
