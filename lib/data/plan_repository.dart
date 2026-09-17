import 'package:flutter/material.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

class PlanRepository {
  final List<Plan> _mockPlans = [
    Plan(
      id: '1',
      name: 'Saturday in Brooklyn',
      date: DateTime(2026, 10, 28),
      meetupTime: const TimeOfDay(hour: 14, minute: 0),
      creatorId: 'YNGXzrllyWQ5RgFJkp6EldugeuZ2',
      activityIds: ['a1'],
      invitations: const [
        Invitation(userId: 'u1', rsvp: RsvpStatus.going),
        Invitation(userId: 'u2', rsvp: RsvpStatus.going),
        Invitation(userId: 'u3', rsvp: RsvpStatus.going),
        Invitation(userId: 'u4', rsvp: RsvpStatus.going),
      ],
    ),
    Plan(
      id: '2',
      name: 'Tech Conference SF',
      date: DateTime(2026, 11, 2),
      meetupTime: const TimeOfDay(hour: 9, minute: 0),
      creatorId: 'u1',
      activityIds: ['a2'],
      invitations: const [Invitation(userId: 'u1', rsvp: RsvpStatus.going)],
    ),
    Plan(
      id: '3',
      name: 'Rooftop Brunch',
      date: DateTime(2026, 6, 28),
      meetupTime: const TimeOfDay(hour: 10, minute: 0),
      creatorId: 'YNGXzrllyWQ5RgFJkp6EldugeuZ2',
      activityIds: ['a3'],
      invitations: const [
        Invitation(userId: 'u1', rsvp: RsvpStatus.going),
        Invitation(userId: 'u5', rsvp: RsvpStatus.going),
      ],
    ),
    Plan(
      id: '4',
      name: 'Wine tasting in Bogota',
      date: DateTime(2026, 10, 28),
      meetupTime: const TimeOfDay(hour: 22, minute: 0),
      creatorId: 'YNGXzrllyWQ5RgFJkp6EldugeuZ2',
      activityIds: ['a4'],
      invitations: const [
        Invitation(userId: 'u1', rsvp: RsvpStatus.invited),
        Invitation(userId: 'u6', rsvp: RsvpStatus.going),
        Invitation(userId: 'u7', rsvp: RsvpStatus.going),
        Invitation(userId: 'u8', rsvp: RsvpStatus.going),
      ],
    ),
  ];

  Future<List<Plan>> getPlansForUser(String userId) async {
    return _mockPlans
        .where(
          (p) =>
              p.creatorId == userId ||
              p.invitations.any((i) => i.userId == userId),
        )
        .toList();
  }
}
