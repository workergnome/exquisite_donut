# Spec for the Exquisite Donut

The Pittsburgh New Media Meetup group is developing a collaborative sculpture installation, currently working under the name "The Exquisite Donut".  This is a multi-artist screen-based installation.

### About the Pittsburgh New Media Meetup

The Pittsburgh New Media Meetup is an informal group of professionals, students, and enthusiasts interested in the intersections of technology, the arts, and media.  We meet monthly to share ideas, find collaborators, and work together to improve our work and the state of new media in the Pittsburgh Area.  

### The Exquisite Donut Concept

The surrealist party game "The Exquisite Corpse" involved drawings made by many artists on a folded piece of paper.  As the paper was passed between artists, each would create a partial drawing and then fold the paper to hide their work, leaving only a few connecting lines visible.  The next artist would interpret the line and continue the drawing in their own style.  

A simple set of rules, combined with common tools and techniques, allows for collaboration between people without coordination.  Once all parties have agreed on the rules, the game progresses and the work is generated without conversation between the artists.  The collaboration comes in trying to anticipate and subvert the other's drawing without having seen it—pushing the total work in new directions by anticipating what others might do and doing something else.

We would like to extend this technique into the New Media world, developing a set of rules that allow us to create new media exquisite corpses, allowing collaboration between many artists on a single work. To do so, we need to agree on rules, make our 'drawings', and then reveal the finished work to ourselves and others.

This document describes the rules of this new game.

### High-level Overview

The installation consists of a circular array of vertically-aligned monitors.  All monitors face outwards, and each monitor is directly aligned with two others, forming a "donut" shape.  Each artist is responsible creating a "drawing" on a single monitor.  

The "drawing" consists of an computer program that renders virtual particles moving across the monitor.  When a particle reaches one of the two bordering edges, the application will send a message to the "drawing" on that side, communicating the velocity, acceleration, and two additional "free" variables of that particle.  The receiving "drawing" will then begin to draw that particle, using the variables passed.  

This **SHOULD** result in a single, coherent drawing made up of thousands of particles traveling around the donut, changing form and appearance but maintaining a consistent identity across all of the drawings.


### Technical Details

*Hardware Details*

The installation will also include an Ethernet hub, configured to provide DHCP addresses on a local subnet to each connected computer in the 192.168.0.XXX address space.  

Each artist will provide a computer to connect to a monitor and to the Ethernet hub.  Each computer will be configured to boot directly into a full-screen application (known as the **drawing**) and to automatically obtain an IP address from the Ethernet hub via DHCP.

*Networking Details*

Each computer will listen for and send OSC messages on port 9000.

There will be no internet connection available over Ethernet.

## Rules

### Rule 1:  Drawing IDs

**Rule 1.0**

Each drawing will have the ability to be configured at runtime with one value, which will be a number between 0 and 254 (inclusive).  This number represents the **id** of the drawing.

**Rule 1.1**

There **MUST** be a computer with an id of zero.

**Rule 1.2**

The computers **MUST** be numbered with ascending values.  For each monitor, the drawing on the monitor to its left **MUST** have id that is either a larger number or zero, and the  drawing on the monitor to its right **MUST** be a smaller number.  The only exception is computer zero, which **MUST** have a monitor with a higher ID number to its right.

*(These rules should create a ring of computers with ascending IDs in a clockwise direction, rolling over at zero.  There is no requirement that the numbers are directly adjacent to each other.)*

### Rule 2:  OSC Message Sending

**Rule 2.0**

Each drawing **MUST** broadcast, approximately once a second, an OSC message to the `/status` address at IP 192.168.0.255.


This message will consist of the following tags, in order:

Tag Type     | Name  | Description                            | Example
------------:|-------|----------------------------------------|:--------
int32 (i)    | ID    | This drawing's ID                      | 9
int32 (i)    | COUNT | Count of the particles in the drawing  | 1502

**Rule 2.1**

The drawing with the ID of 0 **MUST** broadcast, approximately one a second, an OSC message to the `/control` address at IP 192.168.0.255.

This message will consist of the following tags, in order:

Tag Type     | Name   | Description                                                    | Example
------------:|------- |----------------------------------------------------------------|:--------
OSC-blob (b) | IDLIST | The IDs that it knows about as bytes in ascending order        | 0x00,0x01,0x03,0x05,0x09,0x10
int32 (i)    | MAXP   | The max number of particles allowed per-drawing                | 5000
int32 (i)    | MINP   | The min number of particles allowed per-drawing                | 500
int32 (i)    | MAXC   | The # of particles allowed to be created or destroyed per/sec. | 10
float32 (f)  | MAXV   | The abs max velocity of a particle as a % of horizontal width  | 0.1
float32 (f)  | MAXA   | The abs max delta-v of a particle as a % of horizontal width   | 0.05

**Rule 2.2**

If a drawing has not received a **control** message, a drawing **MUST** ignore this rule.

Each drawing **MUST** broadcast an OSC message whenever a particle crosses its horizontal boundary on either side.  Crossing is defined as:

* If a particle's `x` position is < 0, it is considered crossing on the left.
* If a particle's `x` position is > the horizontal width of the drawing, it is considered crossing on the right.

Each message **SHOULD** be sent to the appropriate recipient ID.

If a particle crosses on the left, the recipient ID is the ID with the lowest ID that is greater than the drawing's ID. If there are no IDs greater than the drawing's ID, the recipient ID is zero.

If a particle crosses on the right, the recipient ID is the ID with the highest ID that is less than the drawing's ID.   If there are no IDs lower than the drawing's ID, the recipient ID is the greatest ID.

The list of possible IDs **SHOULD** be calculated from the data received in the `/control` message.  

*(Send it to ID of the computer next to you.)*

The OSC message **SHOULD** be sent to the `/particle/[RECIPIENT ID]` address at IP 192.168.0.255.  For example, if the recipient ID is 10, the message **SHOULD** be sent to `/particle/10` address.

This message will consist of the following tags, in order:

Tag Type     | Name     | Description                                             | Example
------------:|----------|---------------------------------------------------------|:--------
int32 (i)    | SEND_ID  | The ID of the sending drawing                           | 9
float32 (f)  | YPOS     | The y position as a % of vertical height                | 0.614
float32 (f)  | XVEL     | The x velocity as a % of horizontal width               | 0.014
float32 (f)  | YVEL     | The y velocity as a % of horizontal width               | 0.05
float32 (f)  | XACC     | The x delta-v as a % of horizontal width                | 0.05
float32 (f)  | YACC     | The y delta-v as a % of horizontal width                | -0.05
float32 (f)  | FREE1    | Free parameter 1 as a value 0 <= p <=1                  | 0.5
float32 (f)  | FREE2    | Free parameter 2 as a value 0 <= p <=1                  | 1.0

Each of these values **SHOULD** be taken from the particle that crossed the boundary.
IF XVEL or YVEL is greater than MAXV, send MAXV instead for that value.
If XACC or YACC is greater than MAXA, send MAXA instead for that value.


### Rule 3:  OSC Message Receiving

**Rule 3.0**

The drawing with ID 0 **MUST** listen to the `/status` address.  It **MUST** maintain a timestamped list of all IDs received for rebroadcast over the `/control` address.  It **SHOULD** remove addresses that it hasn't heard from in 10 seconds from that list. It **SHOULD** indicate in some way that a ID has stopped broadcasting.

It **MAY** choose to modify the MAXP, MINP, & MAXC parameters based on the total count of known particles.

**Rule 3.1**

All drawings **MUST** listen to the `/control` address and store the values received for use in other rules.

**Rule 3.2**

All drawings **MUST** listen to the `/particle/[DRAWING ID]` address, where `[DRAWING ID]` is the ID of that drawing.  For example, the drawing with ID 5 **MUST** listen to the `/particle/5` address.

For each message received, it **SHOULD** create a new particle with initial values contained within the message.  

If the XVEL is greater than 0, the new particle **SHOULD** be placed at the leftmost edge of the screen *(position 0)*.  If the XVEL is less than 0, it **SHOULD** be placed at the rightmost edge of the screen. *(position MAX_WIDTH)*.

*(See Rule 5 for more details on how to implement individual particles.)*

### Rule 4:  Aggregate Particles

**Rule 4.0**

Each drawing maintains a persistent list of particles that are on screen, and on each frame they **MUST** modify the position and appearance of every particle based on the internal rules of that particular drawing.

**Rule 4.1**

If there are fewer than MINP particles on screen, each drawing **MAY** create up to MAXC new particles per second.  These particles can be created anywhere within the drawing.  A drawing **MUST NOT** create particles if there are more than MAXP particles on the screen.

**Rule 4.2**

If there are more than MAXP particles on screen, each drawing **MAY** remove up to MAXC particles per second.  Which particles are removed is up to each individual drawing.  A drawing **MUST NOT** remove particles if there are fewer than MINP particles on the screen.

**Rule 4.3**

Drawings **SHOULD** smoothly interpolate XVEL or YVEL towards MAXV as a particle approaches a horizontal edge if XVEL or YVEL exceeds MAXV.  

**Rule 4.4**

Drawings **SHOULD** smoothly interpolate XACC or YACC towards MAXA as a particle approaches a horizontal edge if XACC or YACC exceeds MAXA.  


### Rule 5: Individual Particles

**Rule 5.0**

Each drawing will consist of many particles on screen.  Each particle's appearance and movement is dictated by that particular drawing's internal logic; however, there are several variables that **MUST** be respected.  

Each particle **MUST** have the following parameters:

Name   |  Description     | notes
-------|------------------|---------
 XPOS  | X Position       | Represented by a float where 0.0 indicates the left side of the screen and 1.0 represents the right side of the screen
 YPOS  | Y Position       | Represented by a float where 0.0 indicates the top of the screen and 1.0 represents the bottom of the screen
 XVEL  | X Velocity       | Represented by a float where 1.0 represents the width of the screen
 YVEL  | Y Velocity       | Represented by a float where 1.0 represents the width of the screen
 XACC  | X Acceleration   | Represented by a float where 1.0 represents the width of the screen
 YACC  | Y Acceleration   | Represented by a float where 1.0 represents the width of the screen
 FREE1 | Free Variable #1 | Represented by a float between 0.0 and 1.0
 FREE2 | Free Variable #2 | Represented by a float between 0.0 and 1.0

*(Note that all values are done as percentages of the screen to ensure resolution independence.)*

Particles **MAY** have any number of other parameters, but those parameters will not be transmitted to neighboring drawings.

Drawings may modify these variables for each particle based on their internal logic.

**Rule 5.1**

Velocity is defined as the change in position during one frame.  XPOS should be modified each frame by adding XVEL to it, and YPOS should be modified by adding YVEL to it.

Acceleration is defined as the change in velocity during one frame.  XVEL should be modified each frame by adding XACC to it, and YVEL should be modified each frame by adding YACC to it.

**Rule 5.2**

Acceleration and velocity **SHOULD** respect MAXA and MAXV.  

**Rule 5.3**

Free variables are floats between 0 and 1, and **SHOULD** be mapped to some visual representation.

**Rule 5.4**

Particles that have a XPOS of < 0 or > 1 are considered to have crossed a boundary.  At this point, a OSC message **MUST** be broadcast and the particle **MUST** be removed from the drawing.  See Rule 2.2 for details.

**Rule 5.5**

Particles **SHOULD NOT** have a YPOS of < 0 or > 1.  


### Rule 6:  Miscellaneous Rules

**Rule 6.0**

If a control message is not received within 10 seconds, all drawings **SHOULD** remove ID 0 from their list of known IDs.

*(This **SHOULD** handle ID 0 crashing by routing around it.  If a drawing on either side of ID 0 doesn't implement this rule, ID 0 will become a black hole, and more particles will need to be created.)*

**Rule 6.1**

The # of particles allowed to be created or destroyed per/sec **MUST** always be greater than zero.

*(This **SHOULD** make sure that the system self-regulates, even if a computer misbehaves)*.


**Rule 6.2**

MINP **MUST** be smaller or equal to MAXP.

**Rule 6.3**

MAXC, MAXV, MAXA, MINP, and MAXP **MUST** be greater than zero.

**Rule 6.4**

All drawing **MUST** use a framerate of 60fps when calculating acceleration and velocity.  All drawing **SHOULD** attempt to display particles at 60fps.

## Questions

* Should we have some sort of offset, that allows particles to go offscreen?  
* Do we need to worry about bezels?
