package io.radar.flutter;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;

import androidx.core.app.NotificationCompat;

public class RadarForegroundService extends Service {

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            if (intent.getAction().equals("start")) {
                startPluginForegroundService(intent.getExtras());
            } else if (intent.getAction().equals("stop")) {
                stopForeground(true);
                stopSelf();
            }
        }

        return START_STICKY;
    }

    private void startPluginForegroundService(Bundle extras) {
        Context context = getApplicationContext();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            manager.deleteNotificationChannel("location");
            int importance;
            try {
                importance = Integer.parseInt((String)extras.get("importance"));
            } catch (NumberFormatException e) {
                importance = 1;
            }

            switch(importance) {
                case 2:
                    importance = NotificationManager.IMPORTANCE_DEFAULT;
                    break;
                case 3:
                    importance = NotificationManager.IMPORTANCE_HIGH;
                    break;
                default:
                    importance = NotificationManager.IMPORTANCE_LOW;
            }
            NotificationChannel channel = new NotificationChannel("location", "Location", importance);
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }

        int icon = getResources().getIdentifier((String)extras.get("icon"), "drawable", context.getPackageName());

        PendingIntent pendingIntent;
        boolean clickable = extras.getBoolean("clickable");
        if (clickable) {
            try {
                Class<?> activityClass = Class.forName((String)extras.get("activity"));
                Intent intent = new Intent(this, activityClass);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                pendingIntent = PendingIntent.getActivity(this, 0, intent, 0);
            } catch (ClassNotFoundException e) {
                pendingIntent = null;
            }
        } else {
            pendingIntent = null;
        }

        Notification notification = new NotificationCompat.Builder(context, "location")
            .setContentTitle((CharSequence)extras.get("title"))
            .setContentText((CharSequence)extras.get("text"))
            .setStyle(new NotificationCompat.BigTextStyle().bigText((CharSequence)extras.get("text")))
            .setOngoing(true)
            .setSmallIcon(icon != 0 ? icon : 17301546) // r_drawable_ic_dialog_map
            .setContentIntent(pendingIntent)
            .build();

        int id;
        try {
            id = Integer.parseInt((String)extras.get("id"));
        } catch (NumberFormatException e) {
            id = 0;
        }

        startForeground(id != 0 ? id : 20160525, notification);
    }

    @Override
    public IBinder onBind(Intent intent) {
        throw new UnsupportedOperationException();
    }

}