// import 'package:flame_forge2d/flame_forge2d.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';

// class CollisionSim extends Forge2DGame {
//   CollisionSim() : super(gravity: Vector2.zero(), zoom: 50);

//   @override
//   Future<void> onLoad() async {
//     add(Ball(Vector2(10, 10), Vector2(2, 0), 1, Colors.blue));
//     add(Ball(Vector2(2, 0), Vector2(-2, 0), 2, Colors.red));
//   }
// }

// class Ball extends BodyComponent<CollisionSim> {
//   final Vector2 startPos;
//   final Vector2 velocity;
//   final double radius = 0.5; // meters
//   final double mass;
//   final Color color;

//   Ball(this.startPos, this.velocity, this.mass, this.color);

//   @override
//   Body createBody() {
//     final shape = CircleShape()..radius = radius;
//     final fixtureDef = FixtureDef(shape)
//       ..density = mass
//       ..restitution = 1.0;
//     final bodyDef = BodyDef(
//       type: BodyType.dynamic,
//       position: startPos,
//       linearVelocity: velocity,
//     );
//     return world.createBody(bodyDef)..createFixture(fixtureDef);
//   }

//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);
//     final paint = Paint()..color = color;

//     // Use radius * 50 (the zoom you passed to Forge2DGame constructor)
//     const double zoom = 50;
//     canvas.drawCircle(Offset.zero, radius * zoom, paint);
//   }
// }
