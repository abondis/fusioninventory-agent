package FusionInventory::Agent::Task::Inventory::OS::Win32::Printers;

use FusionInventory::Agent::Task::Inventory::OS::Win32;
use strict;

my @status = (
        'Unknown', # 0 is not defined
        'Other',
        'Unknown',
        'Idle',
        'Printing',
        'Warming Up',
        'Stopped printing',
        'Offline',
        );

my @errStatus = (
        'Unknown',
        'Other',
        'No Error',
        'Low Paper',
        'No Paper',
        'Low Toner',
        'No Toner',
        'Door Open',
        'Jammed',
        'Service Requested',
        'Output Bin Full',
        'Paper Problem',
        'Cannot Print Page',
        'User Intervention Required',
        'Out of Memory',
        'Server Unknown',
        );


sub isInventoryEnabled {1}

sub doInventory {

    my $params = shift;
    my $logger = $params->{logger};
    my $inventory = $params->{inventory};

    my @slots;

    foreach my $Properties
        (getWmiProperties('Win32_Printer',
qw/ExtendedDetectedErrorState HorizontalResolution VerticalResolution Name Comment DescriptionDriverName
 PortName Network Shared PrinterStatus ServerName ShareName PrintProcessor
/)) {

        my $errStatus;
        if ($Properties->{ExtendedDetectedErrorState}) {
            $errStatus = $errStatus[$Properties->{ExtendedDetectedErrorState}];
        }

        my $resolution;

        if ($Properties->{HorizontalResolution}) {
            $resolution =
$Properties->{HorizontalResolution}."x".$Properties->{VerticalResolution};
        }
        $inventory->addPrinter({
                NAME => $Properties->{Name},
                COMMENT => $Properties->{Comment},
                DESCRIPTION => $Properties->{Description},
                DRIVER => $Properties->{DriverName},
                PORT => $Properties->{PortName},
                RESOLUTION => $resolution,
                NETWORK => $Properties->{Network},
                SHARED => $Properties->{Shared},
                STATUS => $status[$Properties->{PrinterStatus}],
                ERRSTATUS => $errStatus,
                SERVERNAME => $Properties->{ServerName},
                SHARENAME => $Properties->{ShareName},
                PRINTPROCESSOR => $Properties->{PrintProcessor},
                });

    }    
}
1;
