package FusionInventory::Agent::Task::Inventory::OS::Win32::Drives;

use FusionInventory::Agent::Task::Inventory::OS::Win32;
use strict;

my @type = (
        'Unknown', 
        'No Root Directory',
        'Removable Disk',
        'Local Disk',
        'Network Drive',
        'Compact Disc',
        'RAM Disk'
        ); 

sub isInventoryEnabled {1}

sub doInventory {

    my $params = shift;
    my $logger = $params->{logger};
    my $inventory = $params->{inventory};

    my $systemDrive = '';
    foreach my $Properties
        (getWmiProperties('Win32_OperatingSystem',
qw/SystemDrive/)) {
        $systemDrive = lc($Properties->{SystemDrive});
    }

    my @drives;
    foreach my $Properties
        (getWmiProperties('Win32_LogicalDisk',
qw/InstallDate Description FreeSpace FileSystem VolumeName Caption VolumeSerialNumber
DeviceID Size DriveType VolumeName/)) {
        push @drives, {

            CREATEDATE => $Properties->{InstallDate},
                       DESCRIPTION => $Properties->{Description},
                       FREE => int($Properties->{FreeSpace}/(1024*1024)),
                       FILESYSTEM => $Properties->{FileSystem},
                       LABEL => $Properties->{VolumeName},
                       LETTER => $Properties->{DeviceID} || $Properties->{Caption},
                       SERIAL => $Properties->{VolumeSerialNumber},
                       SYSTEMDRIVE => (lc($Properties->{DeviceID}) eq $systemDrive),
                       TOTAL => int($Properties->{Size}/(1024*1024)),
                       TYPE => $type[$Properties->{DriveType}] || 'Unknown',
                       VOLUMN => $Properties->{VolumeName},

        };

    }
    foreach (@drives) {
        $inventory->addDrive($_);
    }

}
1;
