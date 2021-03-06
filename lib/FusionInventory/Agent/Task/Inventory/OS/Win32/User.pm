package FusionInventory::Agent::Task::Inventory::OS::Win32::User;

use FusionInventory::Agent::Task::Inventory::OS::Win32;
use strict;

use Win32::OLE::Variant;

use Encode qw(encode);

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;


use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0 );

sub isInventoryEnabled {1}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\CIMV2") or die "WMI connection failed.\n";
    my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Process", "WQL",
            wbemFlagReturnImmediately | wbemFlagForwardOnly);

    foreach my $objItem (in $colItems) {
    
        my $cmdLine = $objItem->{CommandLine};
    
        if ($cmdLine =~ /\\Explorer\.exe/i) {
            my $name = Variant (VT_BYREF | VT_BSTR, '');
            my $domain = Variant (VT_BYREF | VT_BSTR, '');
    
            $objItem->GetOwner($name, $domain);
    
    
           if (Win32::GetOSName() ne 'Win7') {
               $name = encode("UTF-8", $name);
               $domain = encode("UTF-8", $domain);
           }
            $inventory->addUser({ LOGIN => $name, DOMAIN => $domain });
        }
    
    }

    my $machKey= $Registry->Open( "LMachine", {Access=>Win32::TieRegistry::KEY_READ(),Delimiter=>"/"} );
    foreach (
        "SOFTWARE/Microsoft/Windows NT/CurrentVersion/Winlogon/DefaultUserName",
        "SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/LastLoggedOnUser"
    ) {
        my $lastloggeduser=encodeFromRegistry($machKey->{$_});
        if ($lastloggeduser) {
            $lastloggeduser =~ s,.*\\,,;
            $inventory->setHardware({
               LASTLOGGEDUSER => $lastloggeduser
            });
        }
    }


}
1;
