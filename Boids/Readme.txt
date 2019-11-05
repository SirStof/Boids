After seeing Sebastian Lague's video on Boids (https://www.youtube.com/watch?v=bqtqltqcQhw) I remembered learning about this in Uni.
So I looked up my notes from this lecture, and started coding. Here is the result.

The changeable parameters:

In Boids:
	nBoids: The number of boids
		- Too many boids may slow down the simulation
	boidSpeed: The maximum speed of the boids.

	checkDistanceHeading: The maximum distance in which neighbouring boids will be considered for the average velocity.
	checkDistanceCollision: The maximum distance in which neighbouring boids will be considered for avoidance.

In Boid:
	avgHeadingWeight:	How much the velocity of neighbouring boids influences the velocity of this boid.
	avgPosWeight:		How much the global average position of boids influences the velocity of this boid.
	avgAvoidanceWeight:	How much the neighbouring boids influence this boids' desire to avoid them.

Some observations:
At some point the swarm stabilizes and acts very similar to those old-timey screensavers of a logo bouncing around the screen, except in 3D.
If the heading weight is set to 0, the average position of the boids does not change much. However the behavior of the boids reminds me of a swarm of flies.
The cage avoidance system is not perfect. Sometimes some boids will escape. However, if the majority of boids stay within the cage, eventually the escaped boids will fly back into the cage.