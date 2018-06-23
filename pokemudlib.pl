# PokeMUD functions
# License information available in "pokemud" file



# First, set a bunch of defaults.
%cfg = (
	tinyp_port => 4096,
	http_port => 4196,
	ip_address => "0.0.0.0",
	http_ip_address => "",
	server_name => "Disco",
	hostname => "www.CHANGEME.com",
	allow_build => 0,
	allow_emit => 0,
	sendmail => "/usr/sbin/sendmail",
	db_file => "pokemud.db",
	welcome_file => "welcome.txt",
	motd_file => "motd.txt",
	player_help_file => "help.txt",
	gm_help_file => "help_gm.txt",
	wizard_help_file => "help_wiz.txt",
	email_file => "mail.txt",
	homepage_file => "home.html",
	application_file => "application.html",
	accepted_file => "accepted.html",
	mail_aliases_file => "aliases.txt",
	apache_passwords_file => "apache.passwords.txt",
	update_mail_aliases_command => "./updatealiases",
	news_password => "",
	idle_timeout => 86400,
	http_idle_timeout => 600,
	fd_closure_interval => 30,
	http_rows => 40,
	http_cols => 70,
	http_refresh_time => 30,
	dump_interval => 3600,
	flush_output => 32768
	);

# Now load the config file, and overwrite defaults.
open (FILE, "$dataDirectory/$configFile")
		or die "Could not open configuration file $configFile.\n";
while (<FILE>)  {
	next if /^\s*#/;
	next if /^\s*$/;
	chomp;
	# Remove trailing spaces
	s/\s+$//;
	# Remove leading spaces
	s/^\s+//;
	die "Config file error: line $_ unparseable.\n" unless /=/;
	my ($key, $value) = split /\s*=\s*/;
	$cfg{$key} = $value;
	}
close FILE;

# Set HTTP IP address, if it wasn't specified.
$cfg{"http_ip_address"} = $cfg{"ip_address"} unless $cfg{"http_ip_address"};



#
# Set up a bunch of constants.
#

# Version of PokeMUD.
$pokeMudVersion = 0.1;


# Protocols
$tinyp = 0;
$http = 1;

# Protocol states
$httpReadingHeaders = 0;
$httpReadingBody = 1;
$httpWriting = 2;

# Object types
$room = 1;
$player = 2;
$thing = 3;
$pokemon = 4;


# Special IDs
$none = -1;
$home = -2;
$nowhere = -3;

$waitingRoom = 2;

# Colors!  Yay!
my ($R, $B, $UL,
	$Black, $Red, $Green, $Yellow, $Blue, $Magenta, $Cyan, $White)
    = ( chr(27) . '[0m',
	chr(27) . '[1m',
	chr(27) . '[4m',
	chr(27) . '[30m',
	chr(27) . '[31m',
	chr(27) . '[32m',
	chr(27) . '[33m',
	chr(27) . '[34m',
	chr(27) . '[35m',
	chr(27) . '[36m',
	chr(27) . '[37m' );

# I should probably simplify this elsewhere.  Currently this is only for the @cmit command.
my %colors =  # Ah, => makes for implicit quotes on the keys.
	(black   => $Black,
	 red     => $Red,
	 green   => $Green,
	 yellow  => $Yellow,
	 blue    => $Blue,
	 magenta => $Magenta,
	 cyan    => $Cyan,
	 white   => $White );

#Marker for new material in frames
$httpNewMarker = "<a name=\"newest\">#</a>";


#Data for base64 decoder

$base64alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
                  'abcdefghijklmnopqrstuvwxyz'.
                  '0123456789+/';

$base64pad = '=';

$base64initialized = 0;




# Flag values

# Determines whether the user receives color output.
$useColor = 1;

# Gender.
$male = 2;
$female = 4;
$herm = 6;

# Name of location visible in who list
# How about I make this useful?
# Objects can be public, which lets anyone pick it up.
$public = 8;

# This indicates that a pokemon is well-trained,
# and will allow its trainer to use /pmote from it.
$trained = 16;

# This player is a game master, and can do many things
# in their own game room.
$master = 32;

# This player is a wizard. #1 is always a wizard.
$wizard = 64;

# This thing is a container, and can hold other things.
$container = 128;

# This room will log everything that happens in it.
$logging = 256;

# Players in this game can rename their own pokemon.
$rename = 512;

# Players in this game may write their own descriptions.
$descriptions = 1024;

# Can't be seen; or description only, contents invisible
$dark = 2048;

# If true for a room, this location is "grand central station":
# players can see things, hear people speak, etc., but arrivals and
# departures go unnoticed.
# Also works for items, causing pickups and drops to go unannounced.
# Also players, if their movements are not broadcast to the room.
$silent = 4096;

# This player talks in character by default.
$expert = 8192;

# This player wants to know who @emits things.
$spy = 16384;


#For flag setting
%flags = (
	color => $useColor,
	male => $male,
	female => $female,
	public => $public,
	trained => $trained,
	usecolor => $useColor,
	useColor => $useColor,
	master => $master,
	wizard => $wizard,
	dark => $dark,
	silent => $silent,
	expert => $expert,
	spy => $spy,
	);

%flagsProper = (
	color => $useColor,
	male => $male,
	female => $female,
	public => $public,
	trained => $trained,
	master => $master,
	wizard => $wizard,
	dark => $dark,
	silent => $silent,
	expert => $expert,
	spy => $spy,
	);

@flagNames = (
	"color",
	"male",
	"female",
	"public",
	"trained",
	"master",
	"wizard",
	"dark",
	"silent",
	"expert",
	"spy"
	);







#Set these up in a particular order so that we can
#say that, for instance, abbreviations of 'whisper'
#should beat abbreviations of 'who'.

@commandsProperOrder = (
	'/', \&no_command,
	'@wall', \&wall,
	'/help', \&help,
	'/look', \&look,
	'/say', \&say,
	'/ooc', \&ooc,
	'/emote', \&emote,
	'/sayto', \&sayto,
	'/examine', \&examine,
	'/whisper', \&whisper,
	'@games', \&games,
	
	'@set', \&set,
	'@teleport', \&teleport,
	'@create', \&create,
	'@newgame', \&newGame,
	'@newplayer', \&newPlayer,
	
	
	'/motd', \&motd,
	'/welcome', \&welcome
	);











# Set the SIGPIPE handler (grrr)

&plumber;



# Set up commands table in order of precedence.
# Make sure to empty it again if we're reloading.
%commandsTable = ( );

for ($i = 0; ($i < int(@commandsProperOrder)); $i += 2)  {
	my($key) = $commandsProperOrder[$i];
	my($val) = $commandsProperOrder[$i + 1];
	my($j);
	for ($j = 1; ($j <= length($key)); $j++)  {
		my($s) = substr($key, 0, $j);
		next if ($s eq "@");
		if (!exists($commandsTable{$s}))  {
			$commandsTable{$s} = $val;
			}
		}
	}



########################
#                      #
#  Subroutine Airlock  #
#                      #
########################

# Subroutines I copy from old code go here until they get reviewed,
# edited, rewritten, etc.










sub set  {
	my($me, $arg, $arg1, $arg2) = @_;
	# Still not sure how I want to handle this,
	# but it's at least safe for now.
	if (!&gmTest($me))  {
		&no_command($me);
		return;
		}
	my($flag, $id);
	if (($arg1 eq "") || ($arg2 eq ""))  {
		&tellPlayer($me, "Syntax: \@set object = flag or !flag");
		}
	if (substr($arg1, 0, 1) eq "#")  {
		$id = substr($arg1, 1);
		$id = &idBounds($id);
		}
	else  {
		$id = &findContents($objects[$me]{"location"}, $arg1);
		if ($id == $none)  {
			$id = &findContents($me, $arg1);
			}
		}
	if ($id == $none)  {
		&tellPlayer($me, "I don't see that object here.");
		return;
		}
	if ((!&wizardTest($me)) && ($objects[$id]{"owner"} != $me)
			&& ($objects[$me]{"home"} != $id))  {
		&tellPlayer($me, "You don't own that.");
		return;
		}
	if (substr($arg2, 0, 1) eq "!")  {
		if (!$flags{substr($arg2, 1)})  {
			&tellPlayer($me, "No such flag.");
			return;
			}
		$flag = $flags{substr($arg2, 1)};
		# GMs can only modify flags before '64'.
		# So we bitwise AND with all the bits before that
		if (!($flag & 63) and !&wizardTest($me))  {
			&tellPlayer($me, "Only a wizard can do that.");
			return;
			}
		if (($flag == $wizard or $flag == $master) and $id == 1)  {
			&tellPlayer($me, "Player #1 is always a wizard.");
			return;
			}
		$objects[$id]{"flags"} &= ~$flag;
		&tellPlayer($me, "Flag cleared.");
		}
	else  {
		if (!$flags{$arg2})  {
			&tellPlayer($me, "No such flag.");
			return;
			}
		$flag = $flags{$arg2};
		if (!($flag & 63) and !&wizardTest($me))  {
			&tellPlayer($me, "Only a wizard can do that.");
			return;
			}
		if (($flag == $wizard or $flag == $master) and $id == 1)  {
			&tellPlayer($me, "Player #1 is always a wizard.");
			return;
			}
		$objects[$id]{"flags"} |= $flag;
		&tellPlayer($me, "Flag set.");
		}
	}






















sub recycle  {
	my($me, $arg, $arg1, $arg2) = @_;
	my($id);
	my(@list, $e);
	if (!&gmTest($me)) {
		&no_command($me);
		return;
		}
	if ($arg eq "")  {
		&tellPlayer($me, "Usage: \@recycle thing");
		return;
		}
	$id = &findContents($objects[$me]{"location"}, $arg);
	if ($id == $none)  {
		$id = &findContents($me, $arg);
		}
	if ($id == $none)  {
		if (substr($arg, 0, 1) eq "#")  {
			$id = int(substr($arg, 1));
			$id = &idBounds($id);
			}
		}
	if ($id == $none)  {
		&tellPlayer($me, "I don't see that here.");
		return;
		}
	# Now that we've found it, check that it's part of the right game.
	if ( $objects[$me]{"home"} != $objects[$id]{"home"}
			and !&wizardTest($me) )  {
			&tellPlayer($me, "You can't recycle that!");
			return;
			}
	&recycleById($me, $id, 0);
	}

sub recycleById  {
	my($me, $id, $quiet) = @_;
	# Make sure we're allowed to recycle this.
	if (!&wizardTest($me))  {
		# If it's not in your game,
		# or if it's neither a pokemon or a thing, then fail.
		if ( $objects[$id]{"home"} != $objects[$me]{"home"}
				or ($objects[$id]{"type"} != $pokemon
					and $objects[$id]{"type"} != $thing) ) {
			&tellPlayer($me, "You can't recycle that!") unless $quiet;
			return;
			}
		}
	if ($objects[$id]{"type"} == $player)  {
		if (!$quiet)  {
			&tellPlayer($me, 
				"You must \@toad players before recycling them.");
			}
		return;
		}
	if (($id == 0) || ($id == 1))  {
		if (!$quiet)  {
			&tellPlayer($me, "Objects #0 and #1 are indestructible.");
			}
		return;
		}
	# Remove it from its location
	
	&removeContents($objects[$id]{"location"}, $id);
	
	# Reset the flags to keep anything funny like a puzzle
	# flag from interfering with the removal of the contents
	$objects[$id]{"flags"} = 0;
	
	# Send the contents home.  If they live here,
	# recycle them too, unless they are players.
	# If they are players, set their homes to room 0
	# and send them home.
	@list = split(/,/, $objects[$id]{"contents"});
	foreach $e (@list) {
		if ($objects[$e]{"home"} == $id)  {
			if ($objects[$e]{"type"} == $player)  {
				$objects[$e]{"home"} = 0;
				}
			else  {
				&recycle($me, "#" . $e, "", "");
				next;
				}
			}
		&sendHome($e);
		}
	
	if (!$quiet) {
		&tellPlayer($me, $objects[$id]{"name"} . " recycled.");
		}
	#Mark it unused
	$objects[$id] = { };
	# I promise I won't introduce more of this stupidity
	$objects[$id]{"type"} = $none;
	$objects[$id]{"activeFd"} = $none;
	}


























































##############
#            #
#  Commands  #
#            #
##############

sub no_command  {
	my ($me) = @_;
	&tellPlayer($me, "Not a valid command. Try typing /help.");
	}

sub help  {
	my($me, $arg, $arg1, $arg2) = @_;
	my($found);
	# Default to the index entry.
	$arg = "index" unless $arg;
	$arg = "*" . $arg;
	&tellPlayer($me, "");
	# Allow for layered help files.
	# Display from the main help first, then append further info
	# from later files if the player has the credentials.
	$found = help_read($me, $arg, $cfg{"player_help_file"});
	if (&gmTest($me))  {
		$found += &help_read($me, $arg, $cfg{"gm_help_file"});
		}
	if (&wizardTest($me))  {
		$found += &help_read($me, $arg, $cfg{"wizard_help_file"});
		}
	if (!$found)  {
		&tellPlayer($me, 
			"Sorry, there is no such help topic. Try just typing /help.");
		}
	}

sub look  {
	my($me, $arg, $arg1, $arg2) = @_;
	&lookBody($me, $arg, $arg1, $arg2, 0);
	}

sub examine  {
	my($me, $arg, $arg1, $arg2) = @_;
	&lookBody($me, $arg, $arg1, $arg2, 1);
	}

sub say  {
	my($me, $arg, $arg1, $arg2, $to) = @_;
	$arg =~ s/^\s+//;
	if ($to ne "")  {
		my(@ids) = &getIdsSpokenTo($me, $to);
		return if (!int(@ids));
		my($names, $i);
		for ($i = 0; ($i < int(@ids)); $i++)  {
			if ($i > 0)  {
				if ($i == (int(@ids) - 1))  {
					$names .= " and ";
					}
				else  {
					$names .= ", ";
					}
				}
			$names .= &properName($ids[$i]);
			}
		$to = " to $names";
		}
	&tellPlayer($me, "${Cyan}You say$to, \"" . $arg . "\"${R}");
	&tellRoom($objects[$me]{"location"}, $me, $Cyan . &properName($me) . 
		" says$to, \"" . $arg . "\"${R}");
	}

sub sayto  {
	my($me, $arg, $arg1, $arg2) = @_;
	unless ($arg2)  {
		&tellPlayer($me, "Usage: /sayto player = message");
		return;
		}
	&say($me, $arg2, $arg1, $arg2, $arg1);
	}

sub ooc  {
	my($me, $arg, $arg1, $arg2) = @_;
	$arg =~ s/^\s+//;
	$arg = " (${Yellow}OOC${R}): " . $arg;
	&tellRoom($objects[$me]{"location"}, $none, &properName($me) . $arg);
	}

sub emote  {
	my($me, $arg, $arg1, $arg2) = @_;
	$arg =~ s/^\s+//;
	$_ = $arg;
	# Ah, this lets you do things like ":'s face explodes."
	$arg = " " . $arg unless (/^[,']/); #'# This comment fixes mcedit's syntax highlighting.
	&tellRoom($objects[$me]{"location"}, $none, $Cyan . &properName($me) . $arg . ${R});
	}



sub whisper  {
	my($me, $arg, $arg1, $arg2) = @_;
	my($id);
	if (($arg1 eq "") || ($arg2 eq "")) {
		&tellPlayer($me, "Syntax: .person message, .person,person,person message, or /whisper person = message");
		return;
		}
	my(@ids) = &getIdsSpokenTo($me, $arg1);
	# Nobody passed muster
	return unless (!int(@ids));
	my($names, $lnames);
	$names = " ";
	for ($i = 0; ($i < int(@ids)); $i++)  {
		if ($i > 0)  {
			if ($i == (int(@ids) - 1))  {
				$names .= " and ";
				}
			else  {
				$names .= ", ";
				}
			}
		$names .= &properName($ids[$i]);
		}
	$names .= ".";
	my(%ids);
	for $id (@ids)  {
		next if (exists($ids{$id}));
		$ids{$id} = 1;
		my($n) = &properName($id);
		$lnames = $names;
		$lnames =~ s/ $n([,\.\ ])/ you$1/;
		&tellPlayer($id, &properName($me) . " whispers, \"" .
			$arg2 . "\" to$lnames");
		}
	# Did we get any names?
	$names = " no one." if ($names eq " .");
	&tellPlayer($me, "You whisper \"" . $arg2 . "\" to$names");
	}



















sub motd  {
	my($me, $arg, $arg1, $arg2) = @_;
	&sendFile($me, $cfg{"motd_file"});
	}

sub welcome  {
	my($me, $arg, $arg1, $arg2) = @_;
	&sendFile($me, $cfg{"welcome_file"});
	}



sub games  {
	my($me, $arg) = @_;
	if (!&wizardTest($me)) {
		&no_command($me);
		return;
		}
	my($total, $games);
	for ($i = 3; ($i <= $#objects); $i++)  {
		if ($objects[$i]{"type"} == $room)  {
			my (@list, $found);
			@list = split(/,/, $objects[$i]{"contents"});
			foreach (@list)  {
				$found++ if &isLoggedOn($_);
				}
			if ($arg ne "all")  {
				next unless $found;
				}
			if ($games ne "")  {
				$games .= "\n";
				}
			$games .= "#" . $i . ' ' . &properName($i);
			$games .= " ($found players)" if $found;
			$total++;
			if (!($total % 100)) {
				# Flush for extreme cases
				&tellPlayer($me, $games);
				$games = "";
				}
			}
		}
	if ($total % 100) {
		&tellPlayer($me, $games);
		}
	if ($total)  {
		&tellPlayer($me, "Total games: ". $total);
		}
	else  {
		&tellPlayer($me, "No active games.");
		}
	}

sub wall  {
	my($me, $arg, $arg1, $arg2) = @_;
	if (!&wizardTest($me))  {
		&no_command($me);
		return;
		}
	$arg =~ s/^\s+//;
	my($o);
	for $o (@objects)  {
		if ($o->{"type"} == $player)  {
			&tellPlayer($o->{"id"},
				&properName($me) . " yells, \"" 
				. $arg . "\"");
			}
		}
	}

sub create  {
	my($me, $arg, $arg1, $arg2) = @_;
	my($id);
	if (!&gmTest($me))  {
		&no_command($me);
		return;
		}
	if ($arg =~ /^\s*$/)  {
		&tellPlayer($me, "Syntax: \@create nameofthing");
		return;
		}
	$id = &addObject($me, $arg, $thing);
	return if ($id == $none);
	&addContents($me, $id);
	$objects[$id]{"home"} = $objects[$me]{"home"};
	}

sub newGame  {
	my($me, $arg, $arg1, $arg2) = @_;
	if (!&wizardTest($me))  {
		&no_command($me);
		return;
		}
	my $id = &addObject($me, $arg, $room);
	$objects[$id]{"home"} = $id;
	&moveObject($me, $id);
	}

sub newPlayer  {
	my($me, $arg, $arg1, $arg2) = @_;
	if (!&gmTest($me)) {
		&no_command($me);
		return;
		}
	if (($arg1 eq "") || ($arg2 eq ""))  {
		&tellPlayer($me, "Syntax: \@newplayer name = password");
		return;
		}
	if ($arg1 =~ /#/)  {
		&tellPlayer($me, "Sorry, names cannot contain the # character.");
		return;
		}
	if ($arg1 =~ /\s/)  {
		&tellPlayer($me, "Sorry, names cannot contain spaces.");
		return;
		}
	# Get the main player name string.
	my $name = $arg1;
	$name =~ tr/A-Z/a-z/;
	($name) = split(/;/, $name);
	if (exists($playerIds{$name}))  {
		&tellPlayer($me, "Sorry, that name is taken.");
		return;
		}
	my($id);
	$id = &addObject($me, $arg1, $player);
	$playerIds{$name} = $id;
	$objects[$id]{"owner"} = $id;
	# Put them in the waiting room.
	&addContents(2, $id);
	# Set initial info.
	$objects[$id]{"home"} = $objects[$me]{"location"};
	$objects[$id]{"password"} = $arg2;
	$objects[$id]{"flags"} = 0;
	&updateApachePasswords;
	}

sub teleport  {
	my($me, $arg, $arg1, $arg2) = @_;
	if (!&wizardTest($me))  {
		&no_command($me);
		return;
		}
	if ($arg2 eq "")  {
		# Teleport the player if only one argument given.
		if ($arg1 ne "")  {
			$arg2 = $arg1;
			$arg1 = "#" . $me;
			}
		else  {
			&tellPlayer($me, "Syntax: \@teleport thing = #place");
			return;
			}
		}
	if (substr($arg2, 0, 1) ne "#" and $arg2 ne "home")  {
		&tellPlayer($me, "Syntax: \@teleport thing = #place");
		return;
		}
	my($id);
	if (!(substr($arg1, 0, 1) eq "#"))  {
		$id = &findContents($objects[$me]{"location"}, $arg1);
		if ($id == $none)  {
			$id = &findContents($me, $arg1);
			}
		}
	else  {
		$id = substr($arg1, 1);
		$id = &idBounds($id);
		}
	if ($id == $none)  {
		&tellPlayer($me, "I don't see that here.");
		return;
		}
	# Now that we've found our object, we can set its home if asked.
	if ($arg2 eq "home")  {
		$arg2 = $objects[$id]{"home"};
		}
	my($arg2id) = substr($arg2, 1);
	if ($objects[$id]{"type"} == $room)  {
		&tellPlayer($me, "You can't teleport that.");
		return;
		}
	$id = &idBounds($id);
	if ($id == $none)  {
		&tellPlayer($me, "That destination id is not valid.");
		return;
		}
	if ($objects[$arg2id]{"type"} != $room)  {
		&tellPlayer($me, "That is not a valid destination.");
		return;
		}
	my($oldLocation) = $objects[$id]{"location"};
	&moveObject($id, $arg2id, "disappears.", "materializes.");
	if ($me != $id)  {
		&tellPlayer($id, &properName($me) . 
			" has teleported you to " . 
			$objects[$arg2id]{"name"} . ".");
		}
	&tellPlayer($me, "Teleported.");
	}










sub shutdown  {
	my($me, $arg, $arg1, $arg2) = @_;
	if (!&wizardTest($me))  {
		&no_command($me);
		return;
		}
	&dump($me, $arg, $arg1, $arg2);
	my($i);
	close(LISTENER);
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if ($activeFds[$i]{"id"} != $none)  {
			&moveObject($activeFds[$i]{"id"}, $waitingRoom);
			}
		&closeActiveFd($i);
		}
	if ($commandLogging) {
		close(CLOG);
		}
	exit 0;
	}

























################
#              #
#  MUD Output  #
#              #
################


sub lookBody  {
	my($me, $arg, $arg1, $arg2, $details) = @_;
	my($id);
	$details = &gmTest($me) if $details;   # This is funky syntax, but simpler.  Only GMs get details.
	if (($arg eq "") || ($arg eq ("#" . $objects[$me]{"location"})))  {
		&describe($me, $objects[$me]{"location"}, $details);
		}
	else  {
		# Look for it here.
		$id = &findContents($objects[$me]{"location"}, $arg);
		# Look for it in inventory.
		if ($id == $none)  {
			$id = &findContents($me, $arg);
			}
		# If it's still not found, but we've got details
		# and a number, we're good.
		if ( $id == $none and $details and
				(substr($arg, 0, 1) eq "#") )  {
			$id = int(substr($arg, 1));
			$id = &idBounds($id);
			# But don't keep it if it's not from this player's game.
			$id = $none unless (&wizardTest($me) or
				$objects[$me]{"home"} eq $objects[$id]{"home"});
			}
		if (($id == $none) || ($objects[$id]{"type"} == $none))  {
			&tellPlayer($me, "I don't see that here.");
			return;
			}
		&describe($me, $id, $details);
		}
	}

sub describe  {
	my($me, $what, $details) = @_;
	my($found);
	$found = 0;
	if ($details)  {
		my($line);
		# Display what kind of thing it is first.
		&tellPlayer($me, $Yellow . ('','Room','Player','Thing','Pokemon')[$objects[$what]{"type"}] . $R);
		$line = $objects[$what]{"name"} . " #" . $what .
			"   ${UL}Owner${R}: " . 
			&properName($objects[$what]{"owner"}) .
			"   ${UL}Game${R}: " . &properName($objects[$what]{"home"}) . '  ';
		&tellPlayer($me, $line);
		# Then give a list of flags.
		# Hide this from GMs if the target is a player.
		if (&wizardTest($me) or $objects[$what]{"type"} != $player)  {
			$line = "${UL}Flags${R}:";
			foreach (@flagNames)  {
				my $key = $_;
				my $val = $flagsProper{$key};
				if ($objects[$what]{"flags"} & $val)  {
					$line .= " " . $key;
					}
				}
			&tellPlayer($me, $line);
			}
		# We'll stick with Wizards only for these details.
		if (&wizardTest($me))  {
			my($tz) = $objects[$what]{"tz"};
			if ($tz ne "")  {
				my($prefix) = "";
				if ($tz < 0)  {
					$tz = -$tz;
					$prefix = "-";
					}
				my($hours, $mins) = (int($tz / 60), $tz % 60);
				&tellPlayer($me, "${UL}Time Zone${R}: " . 
					sprintf("%s%02d:%02d",
						$prefix,
						$hours,
						$mins));
				}
			foreach ("fail", "ofail", "odrop", "success", "osuccess",
						"lock", "gags", "email")  {
				if ($objects[$what]{$_} ne "")  {
					&tellPlayer($me, $UL . ucfirst . $R .
						': '  . $objects[$what]{$_});
					}
				}
			&tellPlayer($me, "${UL}Location${R}: " .
					&properName($objects[$what]{"location"}) .
					" #" . int($objects[$what]{"location"}));
			}
		}
	# If not getting details, just display the name normally.
	else  {
		&tellPlayer($me, "\n${B}" . &properName($what) . ${R});
		}
	
	if ($objects[$what]{"description"} eq "")  {
		&tellPlayer($me, "You see nothing special.");
		}
	else {
		&tellPlayer($me, $objects[$what]{"description"});
		}
	
	# Now show the contents, if they exist.
	my(@list);
	my(%desc, $e);
	@list = split(/,/, $objects[$what]{"contents"});
	$desc = "";
	$first = 1;
	# Don't show contents of dark things.
	if ($details or (!($objects[$what]{"flags"} & $dark)))  {
		# Loop through all contents.
		# Build strings for players, pokemon, and things.
		foreach $e (@list)  {
			my $type = $objects[$e]{"type"};
			# Skip if dark, unless we're examining.
			next if ($objects[$e]{"flags"} & $dark and !($details));
			
			$desc{$type} .= ", " if $desc{$type};
			# Just get the proper name, not aliases.
			my ($name) = &properName($e);
			if ($details)  {
				$desc{$type} .= $name . " #" . $e;
				}
			else  {
				# Special formatting for html output.
				# Makes clickable look links.
				
				$desc{$type} .= "\x01" . $name .
					 ",/look " . $name . "\x02";
				}
			}
		
		# Now format the display for the information.
		&tellPlayer($me, "${Green}Players:${R} " . $desc{$player}) if ($desc{$player});
		&tellPlayer($me, "${Green}Pokemon:${R} " . $desc{$pokemon}) if ($desc{$pokemon});
		&tellPlayer($me, "${Green}Things:${R} " . $desc{$thing}) if ($desc{$thing});
		&tellPlayer($me, "${Green}Visible Exits:${R} " . $desc{$exit}) if ($desc{$exit});
		}
	}





sub tellPlayer  {
	my($who, $what) = @_;
	$what =~ s/\s+$//;
	# Filter annoyances out (apply gag filters).
	my($name);
	$name = &properName($who);
	# If no one with that name is on, stop right here.
	return unless (&isLoggedOn($who));
	$name = quotemeta($name);
	return if (($objects[$who]{"gags"} =~ /^$name[,' ]/i) ||
			($objects[$who]{"gags"} =~ / $name[,' ]/i));
	foreach $gag (split(/ /, $objects[$who]{"gags"}))  {
		if ($gag ne "")  {
			$gag = quotemeta($gag);
			return if ($what =~ /^$gag[,' ]/i); #'# This comment fixes mcedit's syntax highlighting.
			}
		}
	# Strip out colors if player does not have them enabled.
	if (!($objects[$who]{"flags"} & $useColor))  {
		my $esc = chr(27);
		$what =~ s/$esc\[\d+m//g;
		}
	if ($objects[$who]{"httpRecent"})  {
		if ($objects[$who]{"httpNewBatch"})  {
			$objects[$who]{"httpOutput"} =~ s/$httpNewMarker//g;
			$objects[$who]{"httpOutput"} .= $httpNewMarker;
			$objects[$who]{"httpNewBatch"} = 0;
			}
		my($at);
		# HTML escapes, plus word wrap (for 70-character <PRE> "window")
		$what =~ s/&/&amp;/g;
		$what =~ s/</&lt;/g;
		$what =~ s/>/&gt;/g;
		my($nwhat);
		while (&plainlength($what) > $cfg{"http_cols"})  {
			$at = &plainrindex($what, " ", $cfg{"http_cols"});
			last if ($at == -1);
			$nwhat .= substr($what, 0, $at) . "\n";
			$what = substr($what, $at + 1);
			}
		$nwhat .= $what;
		$nwhat = &linkUrls($nwhat);
		$nwhat =~ s/\x01([^\,\x02]+)\,([^\,\x02]+)\x02/&linkEmbed($1, $2)/ge;
		$objects[$who]{"httpOutput"} .= $nwhat . "\n";
		}
	elsif ($objects[$who]{"activeFd"} ne $none)  {
		$what =~ s/\x01([^\,\x02]+)\,([^\,\x02]+)\x02/$1/g;
		&tellActiveFd($objects[$who]{"activeFd"}, $what);
		}
	}

sub tellRoom  {
	my($id, $blind, $what, $from, $topic) = @_;
	my($e, @list);
	my($fromText);
	
	if ($topic eq "")  {
		$fromText = " (from $from)" if ($from ne "");
		}
	@list = split(/,/, $objects[$id]{"contents"});
	foreach $e (@list)  {
		if ($objects[$e]{"type"} == $player)  {
			# Don't include the player initiating the action, in most cases.
			if ($e != $blind)  {
				# Filter annoyances out (apply gag filters).
				if ($from ne "")  {
					my($tgag) = quotemeta($from);
					next if (($objects[$e]{"gags"} =~ /^$tgag /i) ||
							($objects[$e]{"gags"} =~ / $tgag /i));
					}
				#
				# Topics removed.
				# Apply topic filters.
				#next if (!&filterTopic($e, $topic));
				#my($msg) = $what;
				
				# Handle the smartclient prefix for topics.
				#if ($topic ne "")  {
				#	my($prefix) = &getTopicPrefix($e);
				#	$msg = "$prefix$msg";
				#	}
				if ($objects[$e]{"flags"} & $spy)  {
					&tellPlayer($e, $what . $fromText);
					}
				else  {
					&tellPlayer($e, $what);
					}
				}
			}
		}
	}


sub tellWizards  {
	my($msg) = @_;
	my($i);
	# Loop through active connections.
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		my($e) = $activeFds[$i]{"id"};
		if ($e != $none)  {
			# We handle HTTP connections later.
			next if ($objects[$e]{"httpRecent"});
			if (&wizardTest($e))  {
				&tellPlayer($e, $msg);
				}
			}
		}
	foreach $e (@httpActiveIds)  {
		if ($e != $none)  {
			if (&wizardTest($e))  {
				&tellPlayer($e, $msg);
				}
			}
		}
	}


sub substitute  {
	my($me, $arg) = @_;
	my($s, $p, $o, $n, $a, $r, $uname);
	$_ = $arg;
	my $name = &properName($me);
	# &substitute looks for a % to mark elements to change.
	return $arg if (!/%/);
	# Set up the choices.
	my $gend;
	$gend += 1 if ($objects[$me]{"flags"} & $male);
	$gend += 2 if ($objects[$me]{"flags"} & $female);
	# So 0 = none, 1 = male, 2 = female, 3 = herm
	
	# Set up arrays
	my @s = ("it", "he", "she", $name);
	my @p = ("its", "his", "her", $name . "'s");
	my @a = ("its", "his", "hers", $name . "'s");
	my @o = ("it", "him", "her", $name);
	my @r = ("itself", "himself", "herself", $name);
	
	# Now substitute!
	$arg =~ s/\%n/$name/ge;
	$arg =~ s/\%s/$s[$gend]/ge;
	$arg =~ s/\%p/$p[$gend]/ge;
	$arg =~ s/\%a/$a[$gend]/ge;
	$arg =~ s/\%o/$o[$gend]/ge;
	$arg =~ s/\%r/$r[$gend]/ge;
	
	$arg =~ s/\%N/ucfirst $name/ge;
	$arg =~ s/\%S/ucfirst $s[$gend]/ge;
	$arg =~ s/\%P/ucfirst $p[$gend]/ge;
	$arg =~ s/\%A/ucfirst $a[$gend]/ge;
	$arg =~ s/\%O/ucfirst $o[$gend]/ge;
	$arg =~ s/\%R/ucfirst $r[$gend]/ge;
	
	# Allow using '%%' to mean an actual percent sign.
	$arg =~ s/\%\%/\%/g;
	return $arg;
	}




















#########################
#                       #
#  Object Manipulation  #
#                       #
#########################



sub addObject  {
	my($maker, $name, $type) = @_;
	# Don't allow goofy names containing '#'
	if ($name =~ /#/)  {
		tellPlayer($maker, "Sorry, names cannot contain the # symbol.");
		return $none;
		}
	my($id);
	my($found);
	$found = 0;
	# Search old IDs for first available recycled ID.
	for ($id = 0; ($id <= $#objects); $id++)  {
		if ($objects[$id]{"type"} == $none)  {
			$found = 1;
			last;
			}
		}
	# Otherwise, make a new one.
	if (!$found)  {
		$id = $#objects + 1;
		}
	# Clean up spaces in aliases.
	$name =~ s/\s*;\s*/;/g;
	$objects[$id]{"name"} = $name;
	$objects[$id]{"type"} = $type;
	$objects[$id]{"activeFd"} = $none;
	$objects[$id]{"owner"} = $maker;
	&tellPlayer($maker, &properName($id) . " has been created as #" .  $id . ".");
	return $id;
	}

sub addContents  {
	my($addto, $add) = @_;
	
	# Whatever you do, don't let any commas get in here.
	$add =~ s/,//g;
	
	if (length($objects[$addto]{"contents"}) > 0)  {
		$objects[$addto]{"contents"} .= "," . $add;
		}
	else  {
		$objects[$addto]{"contents"} = $add;
		}
	$objects[$add]{"location"} = $addto;
	}

sub removeContents  {
	my($container, $id) = @_;
	my(@list);
	@list = split(/,/, $objects[$container]{"contents"});
	$objects[$container]{"contents"} = "";
	my($e);
	foreach $e (@list)  {
		&addContents($container, $e) if ($e ne $id);
		}
	}

sub sendHome  {
	my($me) = @_;
	&removeContents($objects[$me]{"location"}, $me);
	if ( !($objects[$objects[$me]{"location"}]{"flags"} & $silent)
			&& !($objects[$me]{"flags"} & $silent) )  {
		&tellRoom($objects[$me]{"location"}, $none,
			&properName($me) . " goes home.");
		}
	&addContents($objects[$me]{"home"}, $me);
	if (!($objects[$objects[$me]{"location"}]{"flags"} & $silent)
			&& !($objects[$me]{"flags"} & $silent) )  {
		&tellRoom($objects[$me]{"location"}, $me,
			&properName($me) . " arrives at home.");
		}
	&tellPlayer($me, "You go home.");
	&look($me, "", "", "");
	}

sub moveObject  {
	my ($id, $dest, $depart, $arrive) = @_;
	$depart = "leaves." unless $depart;
	$arrive = "arrives." unless $arrive;
	if ($dest == $home)  {
		$dest = $objects[$id]{"home"};
		}
	my $name = &properName($id);
	&removeContents($objects[$id]{"location"}, $id);
	if ( !($objects[$objects[$id]{"location"}]{"flags"} & $silent)
			&& !($objects[$id]{"flags"} & $silent) )  {
		&tellRoom($objects[$id]{"location"}, $none, $name . " " . $depart);
		}
	&addContents($dest, $id);
	if (!($objects[$objects[$id]{"location"}]{"flags"} & $silent)
			&& !($objects[$id]{"flags"} & $silent) )  {
		&tellRoom($objects[$id]{"location"}, $id, $name . " " . $arrive);
		}
	if (&isLoggedOn($id))  {
		&look($id, "", "", "");
		}
	}







#####################
#                   #
#  Command Parsing  #
#                   #
#####################




sub command  {
	my($me, $text) = @_;
	my($id);
	$objects[$me]{"lastPing"} = $now;
	$_ = $text;
	# Don't let the user embed commands. Could do nasty, nasty things.
	s/\x01/\./g;
	s/\x02/\./g;
	# Clean up whitespace.
	s/\s/ /g;
	s/^ //g;
	s/ $//g;
	$text = $_;
	# Ignore blank commands.
	return if ($text eq "");
	if ($text eq "/quit")  {
		&closePlayer($me, 1);
		return;
		}
	$objects[$me]{"last"} = $now;
	if ($commandLogging)  {
		print CLOG $me, ":", $text, "\n";
		&flush(CLOG);
		}
	# @ indicates an advanced command.
	if ($text =~ /^\@/ and !&gmTest($me) )  {
		&tellPlayer($me, '"@" is reserved for GM commands.');
		return;
		}
	if (substr($text, 0, 1) eq "\"")  {
		&say($me, substr($text, 1), "", "");
		return;
		}
	if (substr($text, 0, 1) eq ":")  {
		&emote($me, substr($text, 1), "", "");
		return;
		}
	# Added /ooc command.
	if (substr($text, 0, 1) eq "'")  {
		&ooc($me, substr($text, 1), "", "");
		return;
		}
	if (substr($text, 0, 1) eq ".")  {
		$text =~ s/^\.(\S+) //;
		&whisper($me, "", $1, $text);
		return;
		}
	
	#
	# Consider exits from this room.
	#
	
	# Removing standard movement feature.
	
	#if (substr($text, 0, 1) ne "@")  {
	#	# Get exit ID
	#	$id = &findContents($objects[$me]{"location"}, $text);
	#	if ($id != $none and $objects[$id]{"type"} == $exit)  {
	#	#	if ($objects[$id]{"type"} != $exit) {
	#	#		&fail($me, $id, "You can't go that way.", "");
	#	#		return;
	#	#	}
	#		if (!&testLock($me, $id))  {
	#			&fail($me, $id, "You can't go that way.", "");
	#			return;
	#			}
	#		if ($objects[$id]{"action"} == $nowhere)  {
	#			&success($me, $id, "",
	#				&properName($me) . " has left.");
	#			return;
	#			}
	#		&removeContents($objects[$me]{"location"}, $me);
	#		unless ( $objects[$objects[$me]{"location"}]{"flags"} & $silent )  {
	#			&success($me, $id, "",
	#				&properName($me) . " has left.");
	#			}
	#		if ($objects[$id]{"action"} == $home)  {
	#			&sendHome($me);
	#			return;
	#			}
	#		unless ($objects[$objects[$id]{"action"}]{"flags"} & $silent
	#				or $objects[$me]{"flags"} & $silent )  {
	#			# For exits, odrop displays a message in the room entered.
	#			if ($objects[$id]{"odrop"} ne "")  {
	#				&tellRoom($objects[$id]{"action"}, $none,
	#					&properName($me) . " " .
	#					&substitute($me, 
	#						$objects[$id]{"odrop"}));
	#				}
	#			else  {
	#				&tellRoom($objects[$id]{"action"}, $none,
	#					&properName($me) . " has arrived.");
	#				}
	#			}
	#		&addContents($objects[$id]{"action"}, $me);
	#		&describe($me, $objects[$me]{"location"}, 0);
	#		return;
	#		}
	#	}
	
	# Split into command and argument.
	
	my($c, $arg) = split(/ /, $text, 2);
	
	$arg = &canonicalizeWord($me, $arg);
	
	# Now commands with an = sign.
	
	# Common parsing
	
	my($arg1, $arg2) = split(/=/, $arg, 2);
	$arg1 = &canonicalizeWord($me, $arg1);
	$arg2 = &canonicalizeWord($me, $arg2);
	
	# Commands that are not in the normal table
	
	$c =~ tr/A-Z/a-z/;
	
	if ($c eq "\@recycle")  {
		&recycle($me, $arg, $arg1, $arg2);
		return;
		}
	if ($c eq "\@purge")  {
		&purge($me, $arg, $arg1, $arg2);
		return;
		}
	if ($c eq "\@toad")  {
		&toad($me, $arg, $arg1, $arg2);
		return;
		}
	if ($c eq "\@shutdown")  {
		&shutdown($me, $arg, $arg1, $arg2);
		return;
		}
	if ($c eq "\@reload")  {
		&reload($me, $arg, $arg1, $arg2);
		return;
		}
	if ($c eq "\@dump")  {
		&dump($me, $arg, $arg1, $arg2);
		return;
		}
	
	if (exists($commandsTable{$c}))  {
		&{$commandsTable{$c}}($me, $arg, $arg1, $arg2);
		return;
		}
	if ( $text =~ m|^/|  or $text =~ m|^\@| )  {
		&tellPlayer($me, "Not a valid command. Try typing /help.");
		}
	else  {
		if ($objects[$me]{"flags"} & $expert)  {
			&say($me, $text, "", "");
			}
		else  {
			&ooc($me, $text, "", "");
			}
		}
	}



sub visibleCanonicalizeWord  {
	my($me, $word) = @_;
	my($id);
	$word =~ s/\s+$//;
	$word =~ s/^\s+//;
	# Ignore blanks.
	return if ($word eq "");
	$word = &canonicalizeWord($me, $word);
	
	# Additional canonicalization
	$id = &findContents($me, $word);
	if ($id != $none)  {
		$word = "#" . $id;
		}
	else  {
		$id = &findContents($objects[$me]{"location"}, $word);
		if ($id != $none)  {
			$word = "#" . $id;
			}
		}
	return $word;
	}

sub canonicalizeWord  {
	my($me, $word) = @_;
	$word =~ s/^\s+//g;
	$word =~ s/\s+$//g;
	if ($word eq "me")  {
		$word = "#" . $me;
		}
	elsif ($word eq "here")  {
		$word = "#" . $objects[$me]{"location"};
		}
	elsif (substr($word, 0, 1) eq "*")  {
		my($name);
		($name = substr($word, 1)) =~ tr/A-Z/a-z/;
		if (exists($playerIds{$name}))  {
			$word = "#" . $playerIds{$name};
			}
		}
	return $word;
	}


sub getIdsSpokenTo  {
	my($me, $arg1) = @_;
	my(@refs) = split(/,/, $arg1);
	my(@ids);
	my($i);
	for $i (@refs)  {
		$i = &canonicalizeWord($me, $i);
		# Hmm, maybe remove say by number...
		if ($i =~ /^#(.*)/)  {
			$id = &idBounds($1);
			}
		else  {
			$i =~ tr/A-Z/a-z/;
			if (!exists($playerIds{$i}))  {
				$id = &findContents(
					$objects[$me]{"location"}, $i, $player);
				if ($id == $none)  {
					&tellPlayer($me, "Sorry, there is no " .
						"player named $i.\n");
					next;
					}
				}
			else  {
				$id = $playerIds{$i};
				}
			}
		if ($objects[$id]{"type"} != $player)  {
			&tellPlayer($me, "$i is an inanimate object.");
			next;
			}
		unless (&isLoggedOn($id))  {
			&tellPlayer($me, "$i is not logged in.");
			next;
			}
		push @ids, $id;
		}
	return @ids;
	}





















#################
#               #
#  Connections  #
#               #
#################


sub connectPlayer  {
	# Do the stuff from httpHandleRequest here.
	}


sub login  {
	my($id, $aindex) = @_;
	if (!($objects[$objects[$id]{"location"}]{"flags"} & $silent))  {
		&tellRoom($objects[$id]{"location"}, $none,
			&properName($id) . " has connected.");
		}
	$objects[$id]{"activeFd"} = $aindex;
	$objects[$id]{"on"} = $now;
	$objects[$id]{"last"} = $now;
	$objects[$id]{"lastPing"} = $now;
	&sendFile($id, $cfg{"motd_file"});
	&moveObject($id, $home, "enters their game.", "has arrived.");
	}












#############
#           #
#  Network  #
#           #
#############



sub selectPass  {
	my($rfds, $wfds, $i);
	$rfds = "";
	$wfds = "";
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if ($activeFds[$i]{"fd"} ne $none)  {
			if ($activeFds[$i]{"protocol"} == $tinyp)  {
				my($fd) = $activeFds[$i]{"fd"};
				vec($rfds, fileno($fd), 1) = 1;
				if (length($activeFds[$i]{"outbuf"}))  {
					vec($wfds, fileno($fd), 1) = 1;
					}
				}
			elsif ($activeFds[$i]{"protocol"} == $http)  {
				my($fd) = $activeFds[$i]{"fd"};
				if (($activeFds[$i]{"state"} == 
						$httpReadingHeaders) || 
						($activeFds[$i]{"state"} == 
						$httpReadingBody))  {
					vec($rfds, fileno($fd), 1) = 1;
					}
				elsif ($activeFds[$i]{"state"} == $httpWriting)  {
					vec($wfds, fileno($fd), 1) = 1;
					}
				}
			}
		}
	vec($rfds, fileno(TINYP_LISTENER), 1) = 1;
	vec($rfds, fileno(HTTP_LISTENER), 1) = 1;
	my($timeout);
	my($before);
	$before = time;
	# The longest timeout would be between dump intervals
	$timeout = $cfg{"dump_interval"} - ($now - $lastdump);
	# Second longest, probably, between fd closure intervals
	if ($fdClosureNew)  {
		# Try it right away
		$timeout = 0;
		}
	else {
		my($fdTimeout);
		$fdTimeout = $lastFdClosure + $cfg{"fd_closure_interval"} - $now;
		$timeout = $fdTimeout if ($fdTimeout < $timeout);
		}
	# Reasonable timeouts only
	$timeout = 0 if ($timeout < 0);
	
	select($rfds, $wfds, undef, $timeout);
	$now = time;
	if ($now - $lastdump >= $cfg{"dump_interval"})  {
		&dump($none, "", "", "");
		}
	if ($fdClosureNew || ($now - $lastFdClosure >= $cfg{"fd_closure_interval"}))  {
		$fdClosureNew = 0;
		# Try to close some file descriptors we're
		# done with.  This can take a while if they have
		# not flushed completely yet, so we make three-second
		# attempts to close them, every n seconds.
		# This is a workaround for the SO_LINGER problem.
		$SIG{ALRM} = \&fdClosureTimeout;
		$fdClosureTimedOut = 0;
		alarm(3);
		while (int(@fdClosureList))  {
			close($fdClosureList[0]);
			if ($fdClosureTimedOut)  {
				# Try again later
				last;
				}
			# It worked
			shift @fdClosureList;
			}
		# No more need for the alarm timer
		alarm(0);
		$SIG{ALRM} = undef;
		$lastFdClosure = time;
		}
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if ($activeFds[$i]{"fd"} ne $none)  {
			my($fd) = $activeFds[$i]{"fd"};
			if (vec($rfds, fileno($fd), 1))  {
				&readData($i, $fd);
				}
			# Watch out for a close detected on the read
			if ($activeFds[$i]{"fd"} ne $none)  {
				if (vec($wfds, fileno($fd), 1))  {
					&writeData($i, $fd);
					}
				}
			}
		}
	if (vec($rfds, fileno(TINYP_LISTENER), 1))  {
		&acceptTinyp;
		}
	if (vec($rfds, fileno(HTTP_LISTENER), 1))  {
		&acceptHttp;
		}
	# Idle Timeouts
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		$e = $activeFds[$i]{"id"};
		if ($e != $none)  {
			next if ($objects[$e]{"httpRecent"});
			$idlesecs = $now - $objects[$e]{"last"};
			if ($idlesecs > $cfg{"idle_timeout"})  {
				&closePlayer($e, 1);
				}
			}
		}
	for ($i = 0; ($i <= $#httpActiveIds); $i++)  {
		if ($httpActiveIds[$i] != $none)  {
			if (($now - $objects[$httpActiveIds[$i]]{"lastPing"}) >
					$cfg{"http_idle_timeout"})  {
				&closePlayer($httpActiveIds[$i], 1);
				}
			elsif (($now - $objects[$httpActiveIds[$i]]{"last"}) >
					$cfg{"idle_timeout"})  {
				&closePlayer($httpActiveIds[$i], 1);
				}
			}
		}
	}

sub acceptTinyp  {
	my($fd) = $fdBase . $fdNum;
	$fdNum++;
	return unless (accept($fd, TINYP_LISTENER));
	my($i, $found);
	$found = 0;
	# First try to reuse an existing file descriptor.
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if ($activeFds[$i]{"fd"} eq $none)  {
			$activeFds[$i]{"protocol"} = $tinyp;
			$activeFds[$i]{"fd"} = $fd;
			$activeFds[$i]{"id"} = $none;
			&sendActiveFdFile($i, $cfg{"welcome_file"});
			$found = 1;
			last;
			}
		}
	# If none are available, make a new one.
	if (!$found)  {
		my($aindex) = $#activeFds + 1;
		$activeFds[$aindex]{"protocol"} = $tinyp;
		$activeFds[$aindex]{"fd"} = $fd;
		$activeFds[$aindex]{"id"} = $none;
		&sendActiveFdFile($aindex, $cfg{"welcome_file"});
		}
	# Stop (ma)lingering behavior
	setsockopt($fd, SOL_SOCKET, SO_LINGER, 0);
	# Set non-blocking I/O
	fcntl($fd, F_SETFL, O_NONBLOCK);
	}

sub acceptHttp  {
	my($fd) = $fdBase . $fdNum;
	$fdNum++;
	return unless (accept($fd, HTTP_LISTENER));
	my($i, $found);
	$found = 0;
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if ($activeFds[$i]{"fd"} eq $none)  {
			$activeFds[$i]{"protocol"} = $http;
			$activeFds[$i]{"state"} = $httpReadingHeaders;
			$activeFds[$i]{"fd"} = $fd;
			$activeFds[$i]{"id"} = $none;
			$found = 1;
			last;
			}
		}
	if (!$found)  {
		my($aindex) = $#activeFds + 1;
		$activeFds[$aindex]{"protocol"} = $http;
		$activeFds[$aindex]{"state"} = $httpReadingHeaders;
		$activeFds[$aindex]{"fd"} = $fd;
		$activeFds[$aindex]{"id"} = $none;
		}
	# Lingering is important for HTTP (2.11)
	setsockopt($fd, SOL_SOCKET, SO_LINGER, 1);
	# Set non-blocking I/O (restored, 2.11)
	fcntl($fd, F_SETFL, O_NONBLOCK);
	}

sub fdClosureTimeout  {
	$fdClosureTimedOut = 1;
	}

sub readData  {
	my($i, $fd) = @_;
	my($got, $len);
	# Append to the input buffer
	$len = length($activeFds[$i]{"inbuf"});
	$got = sysread($fd, $activeFds[$i]{"inbuf"}, 4096, $len);
	if (($got == 0) || 
		((!defined($got)) && ($! != EINTR) && ($! != EAGAIN)))  {
		&closeActiveFd($i);
		return;
		}
	&examineData($i);
	}

sub examineData  {
	my($i) = @_;
	my($where);
	if ($activeFds[$i]{"protocol"} == $http)  {
		if ($activeFds[$i]{"state"} == $httpReadingHeaders)  {
			# MONDO TEDIUM
			my($breaklength);
			my($where, $whereTry);
			$whereTry = index($activeFds[$i]{"inbuf"}, "\n\n");
			$breaklength = 2;
			$where = $whereTry;
			$whereTry = index($activeFds[$i]{"inbuf"}, "\r\r");
			if (($where == -1) || 
				(($whereTry != -1) && ($whereTry < $where)))  {
				$where = $whereTry;
				}
			$whereTry = index($activeFds[$i]{"inbuf"}, "\n\r\n\r");
			if (($where == -1) || 
				(($whereTry != -1) && ($whereTry < $where)))  {
				$breaklength = 4;
				$where = $whereTry;
				}
			$whereTry = index($activeFds[$i]{"inbuf"}, "\r\n\r\n");
			if (($where == -1) || 
				(($whereTry != -1) && ($whereTry < $where)))  {
				$breaklength = 4;
				$where = $whereTry;
				}
			return if ($where == -1);
			$activeFds[$i]{"name"} = "";
			$activeFds[$i]{"password"} = "";
			my($request, @headers, $header);
			$request = substr($activeFds[$i]{"inbuf"},
				0, $where);
			$activeFds[$i]{"inbuf"} = substr($activeFds[$i]{"inbuf"},
				$where + $breaklength);
			$request =~ s/\r\n/\n/g;
			$request =~ s/\r/\n/g;
			@headers = split(/\n/, $request);
			foreach $header (@headers)  {
				my($attr, $value) = split(/\s*:\s*/, $header);
				$attr =~ tr/A-Z/a-z/;
				if ($attr eq "content-length")  {
					$activeFds[$i]{"length"} = $value;
					$activeFds[$i]{"state"} = $httpReadingBody;
					$activeFds[$i]{"request"} = $request;
					}
				elsif ($attr eq "content-type")  {
					$activeFds[$i]{"type"} = $value;
					}
				elsif ($attr eq "authorization")  {
					my($scheme, $value) = split(/\s+/, $value);
					$scheme =~ tr/A-Z/a-z/;
					if ($scheme eq "basic")  {
						$value = &base64decode($value);
						($activeFds[$i]{"name"}, 
						$activeFds[$i]{"password"}) = 
							split(/:/, $value);
						}
					}
				}
			# No body in this request
			if ($activeFds[$i]{"state"} == $httpReadingHeaders)  {
				&httpHandleRequest($i, $request, "",
					$activeFds[$i]{"name"},
					$activeFds[$i]{"password"});
				return;
				}
			}
		if ($activeFds[$i]{"state"} == $httpReadingBody)  {
			if (length($activeFds[$i]{"inbuf"}) >= 
					$activeFds[$i]{"length"})  {
				&httpHandleRequest($i, 
					$activeFds[$i]{"request"},
					$activeFds[$i]{"inbuf"},
					$activeFds[$i]{"name"},
					$activeFds[$i]{"password"});
				}
			return;
			}
		}
	
	# Split into commands
	if ($activeFds[$i]{"inbuf"} =~ /\n/)  {
		@commands = split(/\n/, $activeFds[$i]{"inbuf"});
		my($e);
		my($end);
		$_ = $activeFds[$i]{"inbuf"};
		if (!(/\n$/))  {
			$end = $#commands - 1;
			}
		else  {
			$end = $#commands;
			}
		for ($e = 0; ($e <= $end); $e++)  {
			if (length($commands[$e]))  {
				&input($i, $commands[$e]);
				}
			}
		if ($end == ($#commands - 1))  {
			$activeFds[$i]{"inbuf"} = $commands[$#commands];
			}
		else  {
			$activeFds[$i]{"inbuf"} = "";
			}
		}
	if (length($activeFds[$i]{"inbuf"}) >= 4096)  {
		&input($i, $activeFds[$i]{"inbuf"});
		$activeFds[$i]{"inbuf"} = "";
		}
	}

sub writeData  {
	my($i, $fd) = @_;
	my($got, $len);
	
	# Try to send the output buffer
	$len = length($activeFds[$i]{"outbuf"});
	$got = syswrite($fd, $activeFds[$i]{"outbuf"}, $len);
	if  ((!defined($got)) && ($! != EINTR) && ($! != EAGAIN))  {
		&closeActiveFd($i);
		return;
		}
	$activeFds[$i]{"outbuf"} = substr($activeFds[$i]{"outbuf"}, $got);
	if ($activeFds[$i]{"protocol"} == $http and
			!length($activeFds[$i]{"outbuf"}))  {
		closeActiveFd($i);
		}
	}

sub sendFile  {
	my($id, $fname) = @_;
	if ($objects[$id]{"activeFd"} ne $none)  {
		&sendActiveFdFile($objects[$id]{"activeFd"}, $fname);
		}
	}

sub tellActiveFd  {
	my($active, $what) = @_;
	if ($activeFds[$active]{"protocol"} == $http)  {
		$activeFds[$active]{"outbuf"} .= $what . "\n";
		}
	else  {
		$activeFds[$active]{"outbuf"} .= $what . "\r\n";
		while (length($activeFds[$active]{"outbuf"}) > $cfg{'flush_output'})  {
			$activeFds[$active]{"outbuf"} = "*FLUSHED*" . 
				substr($activeFds[$active]{"outbuf"}, $cfg{'flush_output'} / 2);
			}
		}
	}

sub sendActiveFdFile  {
	my($i, $fname) = @_;
	if (!open(IN, $fname))  {
		&tellActiveFd($i, "ERROR: the file " . $fname .
			" is missing.");
		return;
		}
	while(<IN>)  {
		s/\s+$//;
		&tellActiveFd($i, $_);
		}
	close(IN);
	}


sub closePlayer  {
	my($id) = @_;
	my($i);
	if ($objects[$id]{"httpRecent"})  {
		$objects[$id]{"httpRecent"} = 0;
		$objects[$id]{"httpOutput"} = "";
		for ($i = 0; ($i <= $#httpActiveIds); $i++)  {
			if ($httpActiveIds[$i] == $id)  {
				$httpActiveIds[$i] = $none;
				last;
				}
			}
		}
	for ($i = 0; ($i <= $#activeFds); $i++)  {
		if (($activeFds[$i]{"fd"} ne $none) && ($activeFds[$i]{"id"} == $id))  {
			$activeFds[$i]{"id"} = $none;
			&closeActiveFd($i);
			last;
			}
		}
	$objects[$id]{"activeFd"} = $none;
	if (!($objects[$objects[$id]{"location"}]{"flags"} & $silent))  {
		&tellRoom($objects[$id]{"location"}, $none, &properName($id) . 
			" has disconnected.");
		}
	# Send the player to the waiting room.
	# Maybe make this changeable?
	&moveObject($id, $waitingRoom);
	$objects[$id]{"off"} = $now;
	}

sub closeActiveFd
{
	my($i) = @_;
	if ($activeFds[$i]{"id"} != $none) {
		if (!$objects[$activeFds[$i]{"id"}]{"httpRecent"}) {
			&closePlayer($activeFds[$i]{"id"}, 1);
			return;
		} else {
			$objects[$activeFds[$i]{"id"}]{"activeFd"} = $none;
		}
		$activeFds[$i]{"id"} = $none;
	}
	my($fd);
	$fd = $activeFds[$i]{"fd"};
	if ($fd ne $none) {
		push @fdClosureList, $fd;
		$fdClosureNew = 1;
	}
	# Make sure the next person doesn't get old buffer data!
	$activeFds[$i] = { };
	$activeFds[$i]{"fd"} = $none;
	$activeFds[$i]{"id"} = $none;
	$activeFds[$i]{"smartclient"} = 0;
}


sub base64setup
{
	my($i);
	for ($i = 0; ($i < 64); $i++) {
		$base64table[ord(substr($base64alphabet, $i, 1))] = $i;
	}	
	$base64initialized = 1;
}

sub base64decode
{
	my($arg) = @_;
	my($i, @group, $j, $output, $l, $pad);
	if (!$base64initialized) {
		&base64setup;
	}
	$l = length($arg);
	for ($i = 0; ($i < $l); $i += 4) 
	{
		for ($j = 0; ($j < 4); $j ++) {
			$group[$j] = 
				$base64table[ord(substr($arg, $i + $j, 1))];
		}
		$output .= sprintf("%c%c%c",
			($group[0] << 2) + ($group[1] >> 4),
			(($group[1] & 15) << 4) + (($group[2] & 60) >> 2),
			(($group[2] & 3) << 6) + $group[3]);
	}
	for ($i = ($l - 1); ($i >= 0); $i--) {
		if (substr($arg, $i, 1) eq "=") {
			$pad++;
		}
	}
	if ($pad == 1) {
		$output = substr($output, 0, length($output) - 1);
	} elsif ($pad == 2) {
		$output = substr($output, 0, length($output) - 2);
	}
	return $output;
}

sub plumber  {
	$SIG{'PIPE'} = 'plumber';
	}







##########
#        #
#  HTTP  #
#        #
##########

sub sendHttpHeader  {
	# There is header code in most of the HTTP functions.
	# Move it here.
	&tellActiveFd($i, $_) foreach (
		"HTTP/1.0 200 Success",
		"Server: PokeMUD/" . $pokeMudVersion ,
		"Content-type: text/html",
		"" );
	}

sub httpHandleRequest  {
	my($i, $request, $body, $name, $password) = @_;
	my(@fields, $method, $rawUrl, $url, $protocol,
		$id, $key, $val, $query, $dummy);
	$activeFds[$i]{"outbuf"} = "";
	$activeFds[$i]{"inbuf"} = "";
	$activeFds[$i]{"state"} = $httpWriting;
	@fields = split(/\n/, $request);
	if ($#fields < 0)  {
		# Guh?
		&closeActiveFd($i);
		return;
		}
	@fields = split(/ /, $fields[0]);
	if ($#fields < 2)  {
		# Double guh
		&closeActiveFd($i);
		return;
		}
	$method = $fields[0];
	$rawUrl = join(" ", @fields[1 .. ($#fields - 1)]);
	$protocol = $fields[$#fields];
	# The next session's unique URL component
	my($sessionId);
	$sessionId = int(rand(20000));
	($dummy, $dummy, $url) = split(/\//, $rawUrl);
	$url = $dummy unless $url;
	$name =~ tr/A-Z/a-z/;
	%in = &parseFormSubmission($i, $body);
	if (($name eq "") || ($playerIds{$name} <= 0) ||
		($objects[$playerIds{$name}]{"password"} ne $password))  {
		if (($rawUrl eq "/") || ($rawUrl eq ""))  {
			&frontDoor($i);
			return;
			}
		elsif ($rawUrl eq "/apply")  {
			&application($i);
			return;
			}
		elsif ($rawUrl eq "/completed")  {
			&completedApplication($i, $body);
			return;
			}
		&tellActiveFd($i, $_) foreach (
			"HTTP/1.0 401 Unauthorized",
			"Server: PokeMUD/" . $pokeMudVersion,
			"WWW-Authenticate: Basic realm=\"PokeMUD\"",
			"Content-type: text/html",
			"",
			"<HEAD><TITLE>Authorization Required</TITLE></HEAD>",
			"<BODY><H1>Login Required</H1>",
			$cfg{"server_name"} . " could not verify that you",
			"are a user of the system. ",
			"Either you supplied the wrong",
			"credentials (e.g., bad password), or your",
			"web browser doesn't understand how to",
			"prompt you for the information.<P>",
			"</BODY>");
		return;
		}
	$id = $playerIds{$name};
	&tellActiveFd($i, "HTTP/1.0 200 Success");
	&tellActiveFd($i, "Server: PokeMUD/" . $pokeMudVersion);
	# For crying out loud, PLEASE DON'T cache this! Thanks! Geez!
	if ($url =~ /^upper/)  {
		&tellActiveFd($i, "Pragma: no-cache");
		&tellActiveFd($i, "Expires: Thursday, 2 Jan 97");
		&tellActiveFd($i, "Cache-control: no-store");
		}
	# Top page
	if ($url =~ /^command:(\S+)$/)  {
		# An embedded command. Always produces a new frameset.
		my($c) = $1;
		$c =~ s/%(..)/pack("c",hex($1))/ge;
		&command($id, $c);
		$url = "command";
		}
	else  {
		# Execute the command right away to find out if the
		# user's orientation has changed.
		&command($id, $in{"command"});
		}
	if ($url eq "upper")  {
		&tellActiveFd($i, "Refresh: " . $cfg{"http_refresh_time"} .
			"; URL=/" . $sessionId . "/upper#newest");
		&tellActiveFd($i, "Window-target: upper");
		}
	&tellActiveFd($i, "Content-type: text/html");
	&tellActiveFd($i);
	# Done with header.
	if ($url eq "lower")  {
		&outputCommandForm($i, 1, $sessionId);
		return;
		}
	if ($url ne "upper")  {
		&tellActiveFd($i, $_) foreach (
			"<html>",
			"<head>",
			"<title>" . $cfg{"server_name"} . " WWW Client</title>",
			"</head>",
			"<frameset rows=\"*, 40\"",
			"onLoad=\"frames[1].document.commands.command.focus();\">",
#			"<frame name=\"view\" ",
#			"marginheight=\"1\" ",
#			"src=\"/" .  $sessionId . "/view\">",
			"<frame name=\"upper\" ",
			"marginheight=\"1\" ",
			"src=\"/" .  $sessionId . "/upper#newest\">",
			"<frame name=\"lower\" ",
			"marginheight=\"1\" ",
			"src=\"/" .  $sessionId . "/lower\">",
			"</frameset>");
		if (($url eq "pureframeset") || ($url eq "upper"))  {
			&tellActiveFd($i, "</html>");
			return;
			}
		&tellActiveFd($i, "<noframes>");
		}
	# Okay, it's either the upper (output) frame
	# or a no-frames client.
	if ($objects[$id]{"activeFd"} != $none)  {
		closePlayer($id, 0);
		}
	if (!($objects[$id]{"httpRecent"}))  {
		my($i, $found);
		$objects[$id]{"httpRecent"} = 1;
		$objects[$id]{"httpNewBatch"} = 1;
		$objects[$id]{"httpRows"} = $cfg{"http_rows"}
			unless $objects[$id]{"httpRows"};
		if (!($objects[$objects[$id]{"location"}]{"flags"} & $silent))  {
			&tellRoom($objects[$id]{"location"}, $none,
				&properName($id) . " has connected.");
			}
		$found = 0;
		for ($i = 0; ($i <= $#httpActiveIds); $i++)  {
			if ($httpActiveIds[$i] == $none)  {
				$httpActiveIds[$i] = $id;
				$found = 1;
				last;
				}
			}
		if (!$found)  {
			$httpActiveIds[$#httpActiveIds + 1] = $id;
			}
		&login($id, $none);
		}
	$activeFds[$i]{"id"} = $id;
	my(@rows, $extra, $rows);
	$rows = $objects[$id]{"httpRows"};
	@rows = split(/\n/, $objects[$id]{"httpOutput"});
	$extra = ($#rows + 1) - $rows;
	if ($extra > 0)  {
		$objects[$id]{"httpOutput"} = join("\n", @rows[$extra .. $#rows]);
		$objects[$id]{"httpOutput"} .= "\n";
		}
	&tellActiveFd($i, "<pre>");
	my($copy);
	$copy = $objects[$id]{"httpOutput"};
	$copy =~ s/\s+$//;
	&tellActiveFd($i, $copy);
	&tellActiveFd($i, "</pre>");
	$objects[$id]{"lastPing"} = $now;
	if ($url ne "upper")  {
		&outputCommandForm($i, 0, $sessionId);
		&tellActiveFd($i, "</noframes>");
		&tellActiveFd($i, "</html>");
		}
	else  {
		$objects[$id]{"httpNewBatch"} = 1;
		}
	}


sub frontDoor  {
	my($i) = @_;
	&sendHttpHeader($i);
	&sendActiveFdFile($i, $cfg{"homepage_file"});
	}


sub application  {
	my($i) = @_;
	&sendHttpHeader($i);
	&sendActiveFdFile($i, $cfg{"application_file"});
	}

sub completedApplication  {
	my($fd, $body) = @_;
	my($name, $password, $i);
	%in = &parseFormSubmission($fd, $body);
	$name = $in{"name"};
	$name =~ s/^\#//g;
	$name =~ s/ //g;
	$email = $in{"email"};
	$email =~ s/ //g;
	&sendHttpHeader($i);
	my($copy) = $name;
	$copy =~ tr/A-Z/a-z/;
	if (exists($playerIds{$copy}))  {
		&tellActiveFd($fd, $_) foreach (
			"<title>Application Problem</title>",
			"<h1>Application Problem</h1>",
			"Your application could not be accepted ",
			"because another user has already taken ",
			"the name you requested.",
			"<p>",
			"<strong>",
			"<a href=\"/apply\">Apply Again</a>",
			"</strong>" );
		return;
		}
	# Check allowed-users file first, if it exists
	if (open(ALLOWED, "allowed.txt"))  {
		my($reg, $qreg, $allowed);
		$allowed = 0;
		while ($reg = <ALLOWED>)  {
			chomp $reg;
			next if ($reg =~ /^\s*$/);
			$qreg = "\Q$reg";
			$allowed = 1 if ($email =~ /$qreg$/);
			}
		if (!$allowed)  {
			&tellActiveFd($fd, $_) foreach (
				"<title>Application Rejected</title>",
				"<h1>Application Rejected</h1>",
				"Sorry, that address is not permitted to receive an account.");
			return;
			}
		close(ALLOWED);
		}
	# Check lockouts file second, if it exists
	if (open(LOCKOUTS, "lockouts.txt"))  {
		my($reg, $qreg);
		while ($reg = <LOCKOUTS>)  {
			chomp $reg;
			next if ($reg =~ /^\s*$/);
			$qreg = "\Q$reg";
			if ($email =~ /$qreg$/)  {
				&tellActiveFd($fd, $_) foreach (
					"<title>Application Rejected</title>",
					"<h1>Application Rejected</h1>",
					"Sorry, that address is not permitted to receive an account.");
				return;
				}
			}
		close(LOCKOUTS);
		}
	if ($name eq "")  {
		&tellActiveFd($fd, $_) foreach (
			"<title>Application Problem</title>",
			"<h1>Application Problem</h1>",
			"Your application could not be accepted ",
			"because you did not provide a name!",
			"<p>",
			"<strong>",
			"<a href=\"/apply\">Apply Again</a>",
			"</strong>");
		return;
		}
	if ($email eq "")  {
		&tellActiveFd($fd, $_) foreach (
			"<title>Application Problem</title>",
			"<h1>Application Problem</h1>",
			"Your application could not be accepted ",
			"because you did not provide a valid ",
			"email address.",
			"<p>",
			"<strong>",
			"<a href=\"/apply\">Apply Again</a>",
			"</strong>");
		return;
		}
	# Generate random password.
	for ($i = 0; ($i < 6); $i++)  {
		$password .= sprintf("%c", int(rand(26)) + ord("a"));
		}
	my($id);
	if (!(open(SENDMAIL, "|" . $cfg{"sendmail"} . " -t")))  {
		&tellActiveFd($fd, $_) foreach (
			"<title>System Configuration Error</title>",
			"<h1>System Configuration Error</h1>",
			"This PokeMUD server is misconfigured.",
			"The sendmail program cannot be located.",
			"Please contact the administrator.");
		return;
		}
	# Mail the account info to the user.
	print SENDMAIL (
		"To: " . $in{"email"} . "\n",
		"Subject: YOUR " . $cfg{"server_name"} . " ACCOUNT IS READY!\n",
		"\n",
		"Your user name is: " . $name . "\n",
		"Your password is: " . $password . "\n\n",
		"TO CONNECT, access this URL:\n\n",
		"http://" . $cfg{"hostname"} . ":" . $cfg{"http_port"} . "/\n\n",
		"KEEP YOUR PASSWORD IN A SAFE PLACE. Please do not\n",
		"use this password for other purposes.\n\n");
	if (open(MAIL, $cfg{"email_file"}))  {
		print SENDMAIL while (<MAIL>);
		close(MAIL);
		}
	if (open(ACCOUNTLOG, ">>accounts.log"))  {
		print ACCOUNTLOG $name, " ", $email, "\n";
		close(ACCOUNTLOG);
		}
	close(SENDMAIL);
	$id = &addObject(1, $name, $player);
	$playerIds{$copy} = $id;
	$objects[$id]{"owner"} = $id;
	&addContents(0, $id);
	$objects[$id]{"password"} = $password;
	if ($cfg{"allow_build"})  {
		$objects[$id]{"flags"} = $builder;
		}
	else  {
		$objects[$id]{"flags"} = 0;
		}
	&sendActiveFdFile($fd, $cfg{"accepted_file"});
	}

sub tellActiveFdHtml  {
	my($fd, $arg) = @_;
	&tellActiveFd($fd, $arg);
	&tellActiveFd($fd, "<br>");
	}


sub outputCommandForm  {
	my($i, $frameFlag, $sessionId) = @_;
	if ($frameFlag)  {
		&tellActiveFd($i,
			"<form name=\"commands\" " .
			"action=\"/" . $sessionId . "/frameset" . 
			"\" target=\"_top\" method=\"POST\" " .
			"onSubmit=\"queueClear()\">");
		}
	else  {
		&tellActiveFd($i,
			"<form action=\"/" . $sessionId . 
			"/frameset\" method=\"POST\">");
		}
	if ($frameFlag)  {
		&tellActiveFd($i, 
			"<input type=\"text\" " .
			"size=\"40\" name=\"command\">");
		&tellActiveFd($i, 
			"<input type=\"submit\" " .
			"value=\"Go\" name=\"update\">");
		}
	else  {
		&tellActiveFd($i, 
			"<input type=\"text\" " .
			"size=\"30\" name=\"command\"> ");
		&tellActiveFd($i, 
		"<input type=\"submit\" name=\"update\" value=\"Go\">");
		}
	
	if ($frameFlag)  {
		&tellActiveFd($i, $_) foreach (
			"</form>",
			"<script>",
			"function queueClear ()  {",
			"	setTimeout('clearCommand()', 500)",
			"	return 1",
			"}",
			"function clearCommand ()  {",
			"	document.commands.command.value = \"\"",
			"}",
			"</script>");
		}
	else  {
		&tellActiveFd($i,
			"<br><em><strong>IMPORTANT: </strong> you must click 'Go'" .
			" in order to see more output. For a better interface that" .
			" does <strong>not</strong> require this, use " .
			"<a href=\"http://www.netscape.com/\">Netscape 2.0</a>.</em>");
		}
	}

sub encodeInput  {
	my($in) = @_;
	my($key, $val, $s, $first);
	my($i, $l, $ch);
	$first = 1;
	while (($key, $val) = each(%{$in}))  {
		$s .= "&" unless $first;
		$first = 0;
		$s .= &encodeUrl($key) . "=" . &encodeUrl($val);
		}
	return $s;
	}

sub encodeUrl  {
	my($key) = @_;
	my($l, $i, $ch, $s);
	$s = "";
	$l = length($key);
	for ($i = 0; ($i < $l); $i++)  {
		$ch = substr($key, $i, 1);
		if ($ch =~ /[^\w\.\#\:\/\~]/)  {
			$s .= sprintf("%%%2x", ord($ch));
			}
		else  {
			$s .= $ch;
			}
		}
	return $s;
	}

sub linkUrls  {
	my($l) = @_;
	my(@words, $w, $r);
	@words = split(/(\s+)/, $l);
	$r = "";
	#Surround URLs with equivalent links
	$first = 1;
	foreach $w (@words)  {
		if ($w =~ /\s+/)  {
			$r .= $w;
			}
		elsif ($w =~ /(["',]*)([a-zA-Z]+:\/\/[\w:\.%@\-\/~]+[\w~\/])(\S*)/)  {  #"# Comment to fix syntax highlighting
			$r .= $1 . "<a target=\"_new\" href=\"" . 
				&encodeUrl($2) . "\">" . $2 . "</a>" . $3;
			}
		elsif ($w =~ /(["',]*)([\w\.%\-!]+@[\w\.%\-!]+[\w])(\S*)/)  {  #"# Comment to fix syntax highlighting
			$r .= $1 . "<a href=\"mailto:" . &encodeUrl($2) . 
				"\">" . $2 . "</a>" . $3;
			}
		elsif ($w =~ /(["',]*)([\w\.%@\-~\/]+\.[\w:\.%\-~\/]+[\.\/][\w:\.%\-~\/]+[\w~\/])(\S*)/)  {  #"# Comment to fix syntax highlighting
			$r .= $1 . "<a target=\"_new\" href=\"http://" . 
				&encodeUrl($2) . "\">" . $2 . "</a>" . $3;
			}
		else  {
			$r .= $w;
			}
		}
	return $r;
	}

sub linkEmbed  {
	my($text, $command) = @_;
	my($result);
	$result = "<a target=\"_top\" href=\"/" .  int(rand(20000)) . 
		"/command:" .  &encodeUrl($command) . "\">" . $text . "</a>";
	return $result;
	}

sub plainlength  {
	my($arg) = @_;
	$arg =~ s/\x01([^\,\x02]+)\,([^\,\x02]+)\x02/$1/g;
	return length($arg);
	}

sub plainrindex  {
	my($in, $sub, $last) = @_;
	my($foo) = substr($in, 0, $last);
	my($end, $break, $lat, $gat, $plen);
	$end = 0;
	# Count 'last' non-escaped characters.
	while (1)  {
		$lat = index($in, "\x01", $end);
		if ($lat == -1)  {
			$last = $end + ($last - $plen);
			last;
			}
		if (($plen + ($lat - $end)) >= $last)  {
			$last = $end + ($last - $plen);
			last;
			}
		$plen += ($lat - $end);
		$gat = index($in, "\x02", $lat + 1);
		if ($gat == -1)  {
			# Uh-oh, play dumb
			return -1;
			}
		my $cat = index($in, ",", $lat + 1);
		return -1 if ($cat == -1);  # Bad craziness.
		$plen += ($cat - $lat - 1); 
		if ($plen >= $last)  {
			$last = $lat;
			last;
			}
		$end = $gat + 1;
		}
	# Okay, now we know where the real limiting point is...
	$at = rindex($in, $sub, $last);
	# Hackery to ensure we never break up an embedded link
	while ($at != -1)  {
		$gat = index($in, "\x02", $at);
		$lat = index($in, "\x01", $at);
		last if ($gat == -1);
		if (($lat == -1) || ($gat < $lat))  {
			if ($at != 0)  {
				$at = rindex($in, $sub, $at - 1);
				}
			else  {
				$at = -1;
				}
			}
		else  {
			last;
			}
		}
	return $at;
	}





##############
#            #
#  Accounts  #
#            #
##############

sub parseFormSubmission  {
	my($i, $arg) = @_;
	if ($activeFds[$i]{"type"} =~ "application/x-www-form-urlencoded")  {
		return &parseUrlEncoded($arg);
		}
	else  {
		return &parseFileEncoded($i, $arg);
		}
	}

sub parseUrlEncoded  {
	my($arg) = @_;
	my(%in, @in, $id, $key, $val);
	@in = split(/[&;]/, $arg);
	foreach $id (0 .. $#in)  {
		# Remove trailing spaces
		$in[$id] =~ s/\s+$//;
		# Remove leading spaces
		$in[$id] =~ s/^\s+//;
		# Convert pluses to spaces
		$in[$id] =~ s/\+/ /g;
		
		# Split into key and value.
		($key, $val) = split(/=/, $in[$id], 2); # splits on the first =.
		
		# Convert %XX from hex numbers to alphanumeric
		$key =~ s/%(..)/pack("c",hex($1))/ge;
		$val =~ s/%(..)/pack("c",hex($1))/ge;
		$in{$key} .= $val;
		}
	return %in;
	}

sub parseFileEncoded  {
	# Borrow a bit from cgi-lib
	my($i, $arg) = @_;
	my(%in, @in, $id, $key, $val, $ctype, $boundary);
	$ctype = $activeFds[$i]{"type"};
	if ($ctype =~ /^multipart\/form-data\; boundary\=(.+)$/)  {
		$boundary = $1;
		}
	else  {
		# Uh-oh, unparseable.
		return %in;
		}
	my($where);
	my($item);
	my(@items);
	@items = split(/-*$boundary-*/, $arg);
	foreach $item (@items)  {
		my($header, $body, @headers, $name);
		($header, $body) = 
			split(/\n\n|\r\r|\r\n\r\n|\n\r\n\r/, $item, 2);
		@headers = split(/[\r\n]/, $header);
		foreach $header (@headers)  {
			$header =~ tr/A-Z/a-z/;
			if ($header =~ /^content-disposition\: form\-data\; name=\"(\w+)\"/)  {
				#Finally
				$name = $1;
				$in{$1} = $body;
				last;
				}
			}
		}
	return %in;
	}

sub input  {
	my($aindex, $input) = @_;
	$input =~ tr/\x00-\x1F//d;
	# If we're logged in, just run the command.
	if ($activeFds[$aindex]{"id"} ne $none)  {
		&command($activeFds[$aindex]{"id"}, $input);
		return;
		}
	$input =~ s/\s+/ /g;
	$input =~ s/^ //g;
	$input =~ s/ $//g;
	my($verb, $object, $pwd) = split(/ /, $input);
	return if ($verb eq "");
	if (($verb eq "quit") || ($verb eq "QUIT") || ($verb eq "/quit")) {
		closeActiveFd($aindex);
		return;
		}
	if ($verb eq "news")  {
		if ($cfg{"news_password"} ne "" and
				$input =~ /news\s+$cfg{"news_password"}\s+\#(\d+)\s+(.*)/)  {
			my($to, $what) = ($1, $2);
			if ($objects[$to]{"type"} eq $player)  {
				&tellPlayer($to, $what);
				}
			else  {
				&tellRoom($to, undef, $what, undef);
				}
			closeActiveFd($aindex);
			return;
			}
		else  {
			&tellActiveFd($aindex, "Bad syntax or bad password.");
			closeActiveFd($aindex);
			return;
			}
		}
	if ($verb eq "connect")  {
		my($id, $n);
		$n = $object;
		$n =~ tr/A-Z/a-z/;
		if (!exists($playerIds{$n})) {
			&tellActiveFd($aindex, "Login Failed");
			&tellActiveFd($aindex,
				"That player does not exist, or has a different password.");
			return;
			}
		else  {
			$id = $playerIds{$n};
			if ($pwd ne $objects[$id]{"password"})  {
				&tellActiveFd($aindex, "Login Failed");
				&tellActiveFd($aindex,
					"That player does not exist, or has a different password.");
				return;
				}
			&tellActiveFd($aindex, "Login Succeeded");
			if (($objects[$id]{"activeFd"} != $none) ||
					$objects[$id]{"httpRecent"})  {
				closePlayer($id, 0);
				}
			$activeFds[$aindex]{"id"} = $id;
			&login($id, $aindex);
			}
		return;
		}
	if ($verb eq "smartclient") {
		$activeFds[$aindex]{"smartclient"} = 1;
		return;
		}
	&tellActiveFd($aindex, "Try: connect name password (or quit)");
	}











#####################
#                   #
#  Internal Checks  #
#                   #
#####################


sub idBounds  {
	my($id) = @_;
	$id = $none if ($id > $#objects or $id < 0);
	return $id;
	}

sub wizardTest  {
	my($me) = @_;
	# Object #1 is always a wizard
	return 1 if ($me == 1);
	# How about ordinary wizards?
	return 1 if ($objects[$me]{"flags"} & $wizard);
	return 0;
	}

sub gmTest  {
	my($me) = @_;
	return 1 if ($objects[$me]{"flags"} & $master);
	# Wizards always count.
	return 1 if (&wizardTest($me));
	return 0;
	}

sub findContents  {
	# Looks through contents to find a single match
	
	my($container, $arg, $type) = @_;
	my(@list);
	$arg =~ tr/A-Z/a-z/;
	# Get container contents.
	@list = split(/,/, $objects[$container]{"contents"});
	my($e);
	# First see if we=re looking for an ID.
	if (substr($arg, 0, 1) eq "#")  {
		foreach $e (@list)  {
			if (("#" . $e) eq $arg)  {
				return $e if ((!$type) ||
					($objects[$e]{"type"} == $type));
				}
			}
		return $none;
		}
	# Now look for an exact name match.
	foreach $e (@list)  {
		my($name);
		$name = &properName($e);
		$name =~ tr/A-Z/a-z/;
		return $e if ( ($name eq $arg) and
			(!$type) || ($objects[$e]{"type"} == $type) );
		}
	# Now check name aliases.
	foreach $e (@list)  {
		my(@elist);
		my(@f);
		# Look at each alias separately.
		@elist = split(/;/, $objects[$e]{"name"});
		foreach $f (@elist)  {
			$f =~ tr/A-Z/a-z/;
			return $e if ( ($f eq $arg) and
				(!$type) || ($objects[$e]{"type"} == $type) );
			}
		}
	# Okay, now look for an inexact name match.
	foreach $e (@list)  {
		my($name);
		$name = &properName($e);
		$name =~ tr/A-Z/a-z/;
		return $e if ( substr($name, 0, length($arg)) eq $arg and
			(!$type) || ($objects[$e]{"type"} == $type) );
		}
	# Now check aliases again.
	foreach $e (@list)  {
		my(@elist);
		my(@f);
		@elist = split(/;/, $objects[$e]{"name"});
		foreach $f (@elist)  {
			$f =~ tr/A-Z/a-z/;
			return $e if ( substr($f, 0, length($arg)) eq $arg and
				(!$type) || ($objects[$e]{"type"} == $type) )
			}
		}
	# No results.
	return $none;
	}

sub properName  {
	my ($id) = @_;
	my ($name) = split(/;/, $objects[$id]{"name"});
	return $name;
	}

sub isLoggedOn  {
	my ($id) = @_;
	return 1 if ($objects[$id]{"activeFd"} != $none);
	return 1 if ($objects[$id]{"httpRecent"});
	return 0;
	}


#####################
#                   #
#  File operations  #
#                   #
#####################


sub restore  {
	my($id, $dbVersion, $dbVersionKnown);
	# First try to load the database.
	if (!open(IN, $cfg{"db_file"}))  {
		print "Unable to read from " . $cfg{"db_file"} . ".\n";
		print "Please read the documentation and follow\n";
		print "all of the instructions carefully.\n";
		exit 0;
		}
	$dbVersionKnown = 0;
	while($id = <IN>)  {
		# Get database version requirement from the first line only.
		if (!$dbVersionKnown)  {
			$dbVersionKnown = 1;
			if (!($id =~ /^\d+\.\d+\s*$/))  {
				$dbVersion = 0.0;
				}
			else  {
				$dbVersion = $id;
				if ($dbVersion > $pokeMudVersion)  {
					print "This database was written by ",
					"a newer version of PokeMUD!\n",
					" You need version ",
					$dbVersion . " to read it.\n";
					close(IN);
					return 0;
					}
				next;
				}
			}
		chomp $id;
		# Currently we're at the first version of the database.
		if ($dbVersion >= 0.1)  {
			while (1)  {
				my($attribute, $value, $line);
				$line = <IN>;
				if ($line eq "")  {
					#Uh-oh
					print "Database is truncated!\n";
					return 0;
					}
				chomp $line;
				# Read in one block at a time.
				last if ($line eq "<END>");
				# Get the attribute and the value
				($attribute, $value) = split(/ /, $line, 2);
				# Unescape endlines
				$value =~ s/\\n/\r\n/g;
				# But a slash preceding one of those
				# means an escaped LF is truly wanted
				$value =~ s/\\\r\n/\\n/g;
				$objects[$id]{$attribute} = $value;
				}
			$objects[$id]{"id"} = $id;
			# Build a player lookup table.
			if ($objects[$id]{"type"} == $player)  {
				my ($n);
				$n = &properName($id);
				$n =~ tr/A-Z/a-z/;
				$playerIds{$n} = $id;
				}
			# GOTCHA: $none and 0 are different
			$objects[$id]{"activeFd"} = $none;
			}
		else  {
			# Put old database loading method here.
			}
		}
	close(IN);
	# Make sure Admin is a wizard.
	$objects[1]{"flags"} |= $wizard;
	return 1;
	}


sub dump  {
	my($me, $arg, $arg1, $arg2) = @_;
	if ($me != $none)  {
		if (!&wizardTest($me))  {
			&no_command($me);
			return;
			}
		&tellPlayer($me, "Dumping the database...");
		}
	if (!open(OUT, ">${cfg{'db_file'}}.tmp"))  {
		if ($me != $none)  {
			&tellPlayer($me, 
				"Unable to write to ${cfg{'db_file'}}.tmp\n");
			}
		return;
		}
	my($i);
	my($now) = time;
	# We don't need the current MUD version,
	# we need the last time the database format was changed.
	print OUT "0.1\n";
	# "Oh, this is achingly beautiful"
	# Says PerlMUD.
	for ($i = 0; ($i <= $#objects); $i++)  {
		# Don't save recycled objects
		next if ($objects[$i]{"type"} == $none);
		print OUT $i, "\n";
		# Now regular data
		my($attribute, $value);
		foreach $attribute (keys %{$objects[$i]})  {
			# Important: filter out any connection
			# dependent attributes here if you don't
			# want them dumped and restored.
			
			# Connection dependent. Don't save these.
			next if ($attribute eq "activeFd");
			next if ($attribute eq "httpRecent");
			next if ($attribute eq "lastPing");
			next if ($attribute eq "httpOutput");
			next if ($attribute eq "httpNewBatch");
			
			# Do not attempt to write out the brain
			next if ($attribute eq "brain");
			
			# Already written out.
			next if ($attribute eq "id");
			
			$value = $objects[$i]{$attribute};
			$value =~ s/\\n/\\\\n/g;
			$value =~ s/\r\n/\\n/g;
			$value =~ s/\n/\\n/g;
			# Trim out null values at save time.
			if ($value ne "") {
				print OUT $attribute, " ", $value, "\n";
				}
			}
		print OUT "<END>\n";
		}
	if (!close(OUT))  {
		&wall(1, "Warning: couldn't complete save to ${cfg{'db_file'}}.tmp!");
		# Don't try again right away
		$lastdump = $now;
		return;
		}
	unlink("${cfg{'db_file'}}");
	rename "${cfg{'db_file'}}.tmp", "${cfg{'db_file'}}";
	if ($me != $none)  {
		&tellPlayer($me, "Dump complete.");
		}
	$lastdump = $now;
	}

sub reload  {
	my($me, $arg, $arg1, $arg2) = @_;
	if ($me != $none)  {
		if (!&wizardTest($me))  {
			&no_command($me);
			return;
			}
		}
	&dump($me, $arg, $arg1, $arg2);
	$reloadFlag = 1;
	}

sub help_read  {
	my ($me, $arg, $file) = @_;
	if (!open(IN, $file))  {
		&tellPlayer($me, "ERROR: the file " . $file .
			" is missing.");
		return;
		}
	my $found = 0;
	while(<IN>)  {
		s/\s+$//;
		# Loop until we find the topic marker.
		if ($arg eq $_) {
			$found = 1;
			last;
			}
		}
	if ($found)  {
		# Then pick up where we left off.
		while(<IN>) {
			s/\s+$//;
			# Go until the next topic.
			last if (substr($_, 0, 1) eq "*");
			&tellPlayer($me, $_);
			}
		}
	close(IN);
	return $found;
	}

sub updateApachePasswords  {
	my($key, $val);
	if (!open(OUT, ">$cfg{'apache_passwords_file'}"))  {
		print STDERR "PokeMUD: Write to $cfg{'apache_passwords_file'} failed.\n";
		return;
		}
	while (($key, $val) = each (%playerIds))  {
		my($password) = $objects[$val]{"password"};
		my($enc) = crypt($password,
			pack("CC", 
			ord('a') + rand(26), 
			ord('a') + rand(26)));
		print OUT &properName($val) . ":$enc\n";
		}
	close(OUT);
	}



1;
