package FusionInventory::Agent::Targets;

use strict;
use warnings;

use threads::shared;

use FusionInventory::Agent::Target;

use Data::Dumper;

sub new {
    my (undef, $params) = @_;

    my $self = {};

    my $config = $self->{config} = $params->{config};
    my $logger = $self->{logger} = $params->{logger};
    $self->{deviceid} = $params->{deviceid};

    $self->{targets} = [];
    $self->{targets} = [];



    bless $self;

    $self->init();

    return $self;
}

sub addTarget {
    my ($self, $params) = @_;

    my $logger = $self->{'logger'};

    $logger->fault("No target?!") unless $params->{'target'};

    push @{$self->{targets}}, $params->{'target'};

}

sub init {
    my ($self) = @_;

    my $config = $self->{config};
    my $logger = $self->{logger};
    my $deviceid = $self->{deviceid};


    if ($config->{'stdout'}) {
        my $target = new FusionInventory::Agent::Target({
                'logger' => $logger,
                config => $config,
                'type' => 'stdout',
                'deviceid' => $deviceid,
            });
        $self->addTarget({
                target => $target
            });
    }

    if ($config->{'local'}) {
        my $target = new FusionInventory::Agent::Target({
                'config' => $config,
                'logger' => $logger,
                'type' => 'local',
                'path' => $config->{'local'},
                'deviceid' => $deviceid,
            });
        $self->addTarget({
                target => $target
            });
    }

    foreach my $val (split(/,/, $config->{'server'})) {
        my $url;
        if ($val !~ /^http(|s):\/\//) {
            $logger->debug("the --server passed doesn't ".
                "have a protocole, ".
                "assume http as default");
            $url = "http://".$val.'/ocsinventory';
        } else {
            $url = $val;
        }
        my $target = new FusionInventory::Agent::Target({
                'config' => $config,
                'logger' => $logger,
                'type' => 'server',
                'path' => $url,
                'deviceid' => $deviceid,
            });
        $self->addTarget({
                target => $target
            });
    }

}

sub getNext {
    my ($self) = @_;

    my $config = $self->{'config'};
    my $logger = $self->{'logger'};

    if ($config->{'daemon'} or $config->{'daemon-no-fork'} or $config->{'winService'}) {
        while (1) {
            foreach my $target (@{$self->{targets}}) {
                if (time > $target->getNextRunDate()) {
                    return $target;
                }
            }
            sleep(10);
        }
    } elsif ($config->{'lazy'} && @{$self->{targets}}) {
        my $target = shift @{$self->{targets}};
        if (time > $target->getNextRunDate()) {
            $logger->debug("Processing ".$target->{'path'});
            return $target;
        } else {
            $logger->debug("Nothing to do for ".$target->{'path'});
        }
    } elsif ($config->{'wait'}) {
        my $wait = int rand($config->{'wait'});
        $logger->info("Going to sleep for $wait second(s) because of the".
            " wait parameter");
        sleep($wait);
        return shift @{$self->{targets}}
    } else {
        return shift @{$self->{targets}}
    }

    return;
}

sub resetNextRunDate {
    my ($self) = @_;


    foreach my $target (@{$self->{targets}}) {
        $target->resetNextRunDate();
    }


}

1;
