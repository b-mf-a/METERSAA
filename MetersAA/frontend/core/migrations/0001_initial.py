# Generated by Django 4.0.3 on 2022-06-28 16:23

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Computer',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('computer_name', models.CharField(max_length=128, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='DeviceId',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('deviceid_ori', models.CharField(max_length=9)),
                ('deviceid_termid', models.CharField(max_length=4, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='Subnet',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('subnet_address', models.CharField(max_length=15, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='ScanResult',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('scanresult_filedesktoppresent', models.BooleanField()),
                ('scanresult_filecurrentpresent', models.BooleanField()),
                ('scanresult_datetime', models.TextField(verbose_name='date scanned')),
                ('scanresult_computer_id', models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, to='core.computer')),
                ('scanresult_deviceid_id', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.DO_NOTHING, to='core.deviceid')),
                ('scanresult_subnet_id', models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, to='core.subnet')),
            ],
        ),
    ]
