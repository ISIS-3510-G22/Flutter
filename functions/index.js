const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');

initializeApp();

const db = getFirestore();

async function sendRequestNotification(userId, title, body, data) {
  const tokenSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('fcmTokens')
    .get();
  const tokenDocs = tokenSnapshot.docs.filter(
    (doc) => typeof doc.data().token === 'string' && doc.data().token.length > 0,
  );

  if (tokenDocs.length === 0) {
    logger.info('No registered FCM tokens for recipient', { userId });
    return;
  }

  // FCM multicast requests accept at most 500 registration tokens each.
  for (let offset = 0; offset < tokenDocs.length; offset += 500) {
    const chunk = tokenDocs.slice(offset, offset + 500);
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk.map((doc) => doc.data().token),
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: { channelId: 'request_notifications' },
      },
    });

    const removals = [];
    response.responses.forEach((result, index) => {
      if (
        !result.success &&
        [
          'messaging/invalid-registration-token',
          'messaging/registration-token-not-registered',
        ].includes(result.error?.code)
      ) {
        removals.push(chunk[index].ref.delete());
      } else if (!result.success) {
        logger.warn('Could not send request notification', {
          userId,
          code: result.error?.code,
        });
      }
    });
    await Promise.all(removals);
  }
}

exports.notifyOnFriendRequest = onDocumentCreated(
  'friendRequests/{requestId}',
  async (event) => {
    const request = event.data?.data();
    if (!request || request.status !== 'pending' || !request.toUserId) return;

    const senderSnapshot = await db
      .collection('users')
      .doc(request.fromUserId)
      .get();
    const sender = senderSnapshot.data() || {};
    const senderName =
      [sender.name, sender.lastName]
        .filter((part) => typeof part === 'string' && part.trim().length > 0)
        .join(' ')
        .trim() || (sender.username ? `@${sender.username}` : 'Someone');

    await sendRequestNotification(
      request.toUserId,
      'New friend request',
      `${senderName} sent you a friend request.`,
      { type: 'friend_request', requestId: event.params.requestId },
    );
  },
);

exports.notifyOnGroupInvitation = onDocumentCreated(
  'groupInvitations/{invitationId}',
  async (event) => {
    const invitation = event.data?.data();
    if (
      !invitation ||
      invitation.status !== 'pending' ||
      !invitation.userId ||
      !invitation.groupId
    ) {
      return;
    }

    const groupSnapshot = await db
      .collection('groups')
      .doc(invitation.groupId)
      .get();
    const groupName = groupSnapshot.data()?.name || 'a group';

    await sendRequestNotification(
      invitation.userId,
      'New group invitation',
      `You have been invited to ${groupName}.`,
      {
        type: 'group_invite',
        invitationId: event.params.invitationId,
        groupId: invitation.groupId,
      },
    );
  },
);
