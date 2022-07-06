# Generated by Django 4.0.3 on 2022-06-28 16:23

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Location',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('location_name', models.CharField(max_length=200, verbose_name='Name')),
                ('location_phone', models.CharField(blank=True, max_length=15, verbose_name='Phone')),
                ('location_physicaladdress', models.CharField(blank=True, max_length=200, verbose_name='Street Address')),
            ],
        ),
        migrations.CreateModel(
            name='Subnet',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('subnet_address', models.CharField(max_length=15, verbose_name='IP address')),
                ('subnet_location_id', models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, to='masterlist.location', verbose_name='Location')),
            ],
        ),
        migrations.CreateModel(
            name='Section',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('section_name', models.CharField(max_length=200, verbose_name='Name')),
                ('section_location_floor', models.CharField(blank=True, max_length=20, verbose_name='Floor')),
                ('section_location_room', models.CharField(blank=True, max_length=20, verbose_name='Room')),
                ('section_location_id', models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, to='masterlist.location', verbose_name='Location')),
            ],
        ),
        migrations.CreateModel(
            name='DeviceId',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('deviceid_ori', models.CharField(max_length=9, verbose_name='ORI')),
                ('deviceid_termid', models.CharField(max_length=4, unique=True, verbose_name='Term ID')),
                ('deviceid_registered_date', models.DateTimeField(verbose_name='Date registered')),
                ('deviceid_active', models.BooleanField(default=True, verbose_name='Active')),
                ('deviceid_location_id', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.DO_NOTHING, to='masterlist.location', verbose_name='Location')),
                ('deviceid_section_id', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.DO_NOTHING, to='masterlist.section', verbose_name='Section')),
            ],
        ),
    ]