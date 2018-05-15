#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au September 2016
# as a starting point for COMP2041/9041 assignment 2
# http://cgi.cse.unsw.edu.au/~cs2041/assignments/matelook/

use CGI qw/:all/;
use CGI::Carp qw/fatalsToBrowser warningsToBrowser/;


sub main() {
    # print start of HTML ASAP to assist debugging if there is an error in the script
    print page_header();
    
    # Now tell CGI::Carp to embed any warning in HTML
    warningsToBrowser(1);
    # define some global variables
    $debug = 1;
    $users_dir = "dataset-medium";

    #check if correct login
    if(defined param('login') && defined param('username') && defined param('password') && verification(param('username'), param('password'))){
        print ("<div class='alert alert-success' role='alert'>Login Success!</div>");
        print home_page(); 

       
    } elsif(defined param('n')){
        print user_page();

    } elsif (defined param('search')){
        print search_page();

    } elsif (defined param('search_posts')){
        print search_page_posts();

    } elsif (defined param('signup_page')){
        print signup_page();

    } elsif (defined param('forgot_password')){
        print forgot_password();

    } elsif (defined param('send_password')){
        my $zID = param('zID_forgot');
        my $email = param('email_forgot');
        if($zID ne "" && $email ne ""){
            if (-d "$users_dir/$zID"){
                open my $p, "$users_dir/$zID/user.txt" or die "can not open file: $!";
                while (my $line = <$p>){
                    $correct_email = $1 if($line =~ /email=(.*)/);
                    $correct_password = $1 if($line =~ /password=(.*)/);
                }
                close $p;
            }
            if(!(-d "$users_dir/$zID")){
                print ("<div class='alert alert-danger' role='alert'>zID not found!</div>");
                print forgot_password();
            } elsif ($email ne $correct_email){
                print ("<div class='alert alert-danger' role='alert'>Invalid email!</div>");
                print forgot_password();
            } else {
                send_forgot_pass($correct_password, $email);
                print ("<div class='alert alert-success' role='alert'>Password Sent!</div>");
                print login_page();  
            }

        } else {
            print ("<div class='alert alert-danger' role='alert'>Fill out all forms!</div>");
            print forgot_password();
        }

    } elsif(defined param('create_account')){           
        my $full_name = param('full_name_signup');
        my $zID = param('zID_signup');
        my $password = param('password_signup');
        my $p_confirm = param('password_confirm_signup');
        my $email = param('email_signup');
        my $e_confirm = param('email_confirm_signup');

        if ($full_name ne "" && $password ne "" && $p_confirm ne "" && $email ne "" && $e_confirm ne "" && $zID ne ""){
            if ($full_name =~ /[^\w\s]/){
                    print ("<div class='alert alert-danger' role='alert'>Invalid Name: Letters Only!</div>");
                    print signup_page();
            } elsif (-d "$users_dir/$zID"){
                    print ("<div class='alert alert-danger' role='alert'>zID already in use!</div>");
                    print signup_page();
            } elsif ($zID !~ /z[0-9]{7}/){
                    print ("<div class='alert alert-danger' role='alert'>zID must be z followed by 7 digits!</div>");
                    print signup_page();
            } elsif ($password ne $p_confirm){
                    print ("<div class='alert alert-danger' role='alert'>Passwords do not match</div>");
                    print signup_page();
            } elsif ($email ne $e_confirm){
                    print ("<div class='alert alert-danger' role='alert'>Emails do not match</div>");
                    print signup_page();
            } elsif ($email !~ /.*@.*\..*/){
                    print ("<div class='alert alert-danger' role='alert'>Invalid Email Format</div>");
                    print signup_page();
            } else {
                create_account($full_name, $zID, $password, $email);
                print ("<div class='alert alert-success' role='alert'>Account successfully created!</div>");
                print login_page();
            }

        } else {
            print ("<div class='alert alert-danger' role='alert'>Fill out all forms!</div>");
            print signup_page();
        } 

    } else {
        print login_page();
    }

    print page_trailer();
}

sub user_page {
#
# Show formatted details for user "n".
#
    print $log_in;
    my $n = param('n') || 0;
    my @users = sort(glob("$users_dir/*"));
    my $user_to_show  = $users[$n % @users];

    my $details_filename = "$user_to_show/user.txt";
    my $profile_pic = "$user_to_show/profile.jpg";

    #assign each zID to the respective n value and name
    my $i = 0;
    my %users_n;
    my %users_name;
    foreach $user (@users){
        $user = $1 if ($user =~ /.*\/(z[0-9]{7})/);
        $users_n{$user} = $i;
        $i++;

        open my $p, "$users_dir/$user/user.txt" or die "can not open file: $!";
        while (my $line = <$p>){
            if($line =~ /full_name=(.*)/gi){
                $name = $1;
            }  
        }
        close $p;
        $users_name{$user} = $name;
    }

    #print out all the details if found
    open my $p, "$details_filename" or die "can not open $details_filename: $!";
    while (my $line = <$p>){
        $name = $1 if ($line =~ /name=(.*)/);
        $zID = $1 if ($line =~ /zid=(.*)/);
        $birthday = $1 if ($line =~ /birthday=(.*)/);
        $suburb = $1 if ($line =~ /suburb=(.*)/);
        $program = $1 if ($line =~ /program=(.*)/);
        $mates = $1 if ($line =~ /mates=(.*)/);
    }
    close $p;

    my $time = "";
    my $message = "";
    my $posts = "";
    my $time_comment = "";
    my $message_comment = "";
    my $posts_comment = "";
    my $post_number = 0;       
    my $url = "http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=";
    #joining all the posts into one large string
    foreach $post_filename (reverse (glob "$user_to_show/posts/*/post.txt")){
        $post_number = $1 if $post_filename =~ /\/([0-9]*)\//;
        open my $p, "$post_filename" or die "can not open $post_filename: $!";
        while (my $line = <$p>){
            $time = $1 if ($line =~ /time=(.*)/);
            $message = $1 if ($line =~ /message=(.*)/);
            $post = join '</div><div>', "<h4>$name</h4>$time", "$message";
        }  

        close $p;
        $comments = "";
        foreach $comment_filename (glob "$user_to_show/posts/$post_number/comments/*/comment.txt"){
            $comment_number = $1 if $comment_filename =~ /comments\/([0-9]*)\//;
            open my $p, "$comment_filename" or die "can not open $comment_filename: $!";
            while (my $line = <$p>){
                $time_comment = $1 if ($line =~ /time=(.*)/);
                $message_comment = $1 if ($line =~ /message=(.*)/);
                $from_comment = $1 if ($line =~ /from=(.*)/);
                $message_comment =~ s/[^~](z[0-9]{7})/ <a href='$url$users_n{$1}'>$users_name{$1}<\/a>/gi;
                $message_comment =~ s/^(z[0-9]{7})/ <a href='$url$users_n{$1}'>$users_name{$1}<\/a>/gi;

                $comment = join '</div><div>', "<h5><a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$from_comment}'>$users_name{$from_comment}</a></h5>$time_comment", "$message_comment";
            }

            close $p;
            $replies = "";
            foreach $reply_filename (glob "$user_to_show/posts/$post_number/comments/$comment_number/replies/*/reply.txt"){
                open my $p, "$reply_filename" or die "can not open $reply_filename: $!";
                while (my $line = <$p>){
                    $time_reply = $1 if ($line =~ /time=(.*)/);
                    $message_reply = $1 if ($line =~ /message=(.*)/);
                    $from_reply = $1 if ($line =~ /from=(.*)/);
                    $message_reply =~ s/[^~](z[0-9]{7})/ <a href='$url$users_n{$1}'>$users_name{$1}<\/a>/gi;
                    $message_reply =~ s/^(z[0-9]{7})/ <a href='$url$users_n{$1}'>$users_name{$1}<\/a>/gi;

                    $reply = join '</div><div>', "<h6><a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$from_reply}'>$users_name{$from_reply}</a></h6>$time_reply", "$message_reply";
                }
 
                close $p;

                $replies = join '', "$replies", "<div>$reply</div>";
            }
            $comments = join '<hr>', "$comments<br>", "<div>$comment</div><br><h6>Replies</h6>$replies";
        }

        $posts = join '<hr>', "$posts<br>", "<div>$post</div><h4>Comments</h4>$comments";
    }



    $posts =~ s/\\n/\<br\>/g;
    my $next_user = $n + 1;
    my $prev_user = $n - 1;

    $mates =~ s/\[//g;
    $mates =~ s/]//g;
    $mates =~ s/,/\n/g;
    $mates =~ s/ //g;
    @mate_list = split("\n", $mates);
    #acquiring the matelist with just the zIDs

    print("<div class='matelook_container'>");
        print("<div class='matelook_header'>");
            print("<h1>Matelook</h1>");
        print("</div>");
        print("<div class='matelook_content'>");
            print("<div class='matelook_navigation'>");
                print("<h3>Navigation</h3>");
                print("<ul>");
                    print("<li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=0'>Users</a></li>");
                    print("<li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search='>Search</a></li>");
                    print("<li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search_posts=='>Search Posts</a></li>");
                    print("<li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi'>Logout</a></li>");
                print("</ul>");
            print("</div>");
            print("<div class='matelook_user_details'>");

            print("<img src='$user_to_show/profile.jpg' style='float:right;' alt='Unavailable'>\n");
            print("<p>");
            print("<h3>$name<br></h3>");
            print("zID: $zID<br>");
            print("Birthday: $birthday<br>");
            print("Suburb: $suburb<br>");
            print("Program: $program<br>");
            print("Mates:<br>");
            print("</p>");


            #print mates with thumbnail pictures
            foreach $mate (@mate_list) {
                open my $p, "$users_dir/$mate/user.txt" or die "can not open file: $!";
                while (my $line = <$p>){
                $mate_name = $1 if ($line =~ /name=(.*)/);
                }
                close $p;
                print("<a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$mate}'>");
                print("<img src='$users_dir/$mate/profile.jpg' alt='Unavailable' height='42' width='42'>");
                print("$mate_name");
                print("</a>");
                print("<br>");
                }

            print("<p>");
            print("<h3>Recent Posts<br></h3>");
            print("$posts\n");
            print("</p>");

    return <<eof
<p>
<form method="GET" action="">
    <input type="hidden" name="n" value="$next_user">
    <input type="submit" value="Next user" class="matelook_button">
</form>
<form method="GET" action="">
    <input type="hidden" name="n" value="$prev_user">
    <input type="submit" value="Prev user" class="matelook_button">
</form>
</div>

</div>

<div class='matelook_footer'>
Matelook by Vincent Tsai
</div>

</div>
eof
}

sub home_page{
#
# Home page for when you log in
#

#assign zID to name and n value

    my @users = sort(glob("$users_dir/*"));
    my $logged_in = param('username');
    my $i = 0;
    my %users_n;
    my %users_name;
    foreach $user (@users){
        $user = $1 if ($user =~ /.*\/(z[0-9]{7})/);
        $users_n{$user} = $i;
        $i++;

        open my $p, "$users_dir/$user/user.txt" or die "can not open file: $!";
        while (my $line = <$p>){
            if($line =~ /full_name=(.*)/gi){
                $name = $1;
            }  
        }
        close $p;
        $users_name{$user} = $name;
    }

    print <<eof;
    <div class='matelook_container'>
        <div class='matelook_header'>
            <h1>Matelook</h1>
        </div>

        <div class='matelook_content'>

            <div class='matelook_navigation'>
                <h3>Navigation</h3>
                <ul>
                    <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=0'>Users</a></li>
                    <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search='>Search</a></li> 
                    <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search_posts=='>Search Posts</a></li> 
                    <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi'>Logout</a></li>
                </ul>
            </div>

            <div class='matelook_user_details'>
                <h2>Welcome Back,</h2>
                <h2>$users_name{$logged_in}<br><br></h2>
eof
    
    print ("<h4><a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$logged_in}'>Click here to view your profile</a></h4>");
    return <<eof
        </div>
    </div>
    <div class='matelook_footer'>
        Matelook by Vincent Tsai
    </div>

</div>
eof
}

sub login_page{
#
#prints a login page created mostly through bootstrap
#
    return  <<eof
        <form method="POST">
        <div class="container" align=center style="margin-top:25vh">
        <h1>Matelook<small><br>Login below!</small></h1>
            <div style="width:300px; margin-top:40px" align=center>
                <div>
                    <div class="input-group input-group-lg" style="margin-bottom:10px">
                        <span class="input-group-addon"><span class="glyphicon glyphicon-user"></span></span>
                        <input type="text" class="form-control" placeholder="zID" name="username">
                    </div>
                    <div class="input-group input-group-lg" style="margin-bottom:10px">
                        <span class="input-group-addon"><span class="glyphicon glyphicon-lock"></span></span>
                        <input type="password" class="form-control" placeholder="Password" name="password">
                    </div>
                </div>
                <div>
                    <button type="submit" name="login" class="btn btn-success btn-lg"><span class="glyphicon glyphicon-log-in"></span></button>
                </div>
                <div style="margin:10px">
                    <button type="submit" name="signup_page" class="btn btn-primary">Sign Up Here!</button>
                </div>
                <div style="margin:10px">
                    <button type="submit" name="forgot_password" class="btn btn-primary">Forgot Password?</button>
                </div>
            </div>
        </div>
        </form>
eof
}

sub search_page{
#
# Searches any substrings in the users name
#
    my $search_string = param('search') || 0;

    my @users = sort(glob("$users_dir/*"));
    #assign each zID to the respective n value and name
    my $i = 0;
    my %users_n;
    my %users_name;
    foreach $user (@users){
        $user = $1 if ($user =~ /.*\/(z[0-9]{7})/);
        $users_n{$user} = $i;
        $i++;

        open my $p, "$users_dir/$user/user.txt" or die "can not open file: $!";
        while (my $line = <$p>){
            if($line =~ /full_name=(.*)/gi){
                $name = $1;
            }  
        }
        close $p;
        $users_name{$user} = $name;
    }

print <<eof;
<div class='matelook_container'>
    <div class='matelook_header'>
        <h1>Matelook</h1>
    </div>

    <div class='matelook_content'>

        <div class='matelook_navigation'>
            <h3>Navigation</h3>
            <ul>
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=0'>Users</a></li>
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search='>Search</a></li>
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search_posts=='>Search Posts</a></li>  
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi'>Logout</a></li>
            </ul>
        </div>

        <div class='matelook_user_details'>
            <h3>Search for a mate below: <br></h3>
eof

            foreach $users (@users){
                $users = $1 if ($users =~ /.*\/(z[0-9]{7})/);
                open my $p, "$users_dir/$users/user.txt" or die "can not open file: $!";
                while (my $line = <$p>){
                    if($line =~ /full_name=(.*$search_string.*)/gi){
                        $name = $1;
                        print("<a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$users}'>");
                        print("<img src='$users_dir/$users/profile.jpg' alt='Unavailable' height='42' width='42'>");
                        print("$name");
                        print("</a>");
                        print("<br>")
                    }  
                }
                close $p;
            }

    return <<eof
            <form class="navbar-form navbar-left" role="search">
                <div class="form-group">
                    <input type="text" class="form-control" name="search" placeholder="Search">
                </div>
                <button type="submit" class="btn btn-default">Submit</button>
            </form>
        </div>
    </div>
    <div class='matelook_footer'>
        Matelook by Vincent Tsai
    </div>

</div>
eof

}

sub search_page_posts{
#
# Searches any substrings in posts
#

#assign zID to name and n value

    my $search_string = param('search_posts') || 0;
    my @users = sort(glob("$users_dir/*"));

    my $i = 0;
    my %users_n;
    my %users_name;
    foreach $user (@users){
        $user = $1 if ($user =~ /.*\/(z[0-9]{7})/);
        $users_n{$user} = $i;
        $i++;

        open my $p, "$users_dir/$user/user.txt" or die "can not open file: $!";
        while (my $line = <$p>){
            if($line =~ /full_name=(.*)/gi){
                $name = $1;
            }  
        }
        close $p;
        $users_name{$user} = $name;
    }





print <<eof;
<div class='matelook_container'>
    <div class='matelook_header'>
        <h1>Matelook</h1>
    </div>

    <div class='matelook_content'>

        <div class='matelook_navigation'>
            <h3>Navigation</h3>
            <ul>
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=0'>Users</a></li>
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search='>Search</a></li> 
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?search_posts=='>Search Posts</a></li> 
                <li> <a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi'>Logout</a></li>
            </ul>
        </div>

        <div class='matelook_user_details'>
            <h3>Search for a post below: <br></h3>
eof
            foreach $users (@users){
                foreach $post_filename (reverse (glob "$users_dir/$users/posts/*/post.txt")) {
                open my $p, "$post_filename" or die "can not open $post_filename: $!";
                    while (my $line = <$p>){
                        $time = $1 if ($line =~ /time=(.*)/);
                        $from = $1 if ($line =~ /from=(.*)/);
                    }
                close $p;
                open my $p, "$post_filename" or die "can not open $post_filename: $!";
                    while (my $line = <$p>){
                        if ($line =~ /message=(.*$search_string.*)/){
                            $message = $1;
                            $message =~ s/\\n/<br>/g;
                            print("<a href='http://cgi.cse.unsw.edu.au/~z5117113/ass2/matelook.cgi?n=$users_n{$users}'>");
                            print ("$users_name{$users}<br>");
                            print("</a>");
                            print ("$time<br>");
                            print ("$message<br><hr>");
                        }
                    }
                close $p;
                }
            }

    return <<eof
            <form class="navbar-form navbar-left" role="search">
                <div class="form-group">
                    <input type="text" class="form-control" name="search_posts" placeholder="Search Posts">
                </div>
                <button type="submit" class="btn btn-default">Submit</button>
            </form>
        </div>
    </div>
    <div class='matelook_footer'>
        Matelook by Vincent Tsai
    </div>

</div>
eof

}
sub send_forgot_pass{
#
# Sends forgotten password to email
#
    my($correct_password, $email) = @_;
    open F, '|-', 'mail', '-s', 'Matelook Password Recovery', $email or die "Could not send email: $!";
    print F "Hello!\nIt appears that you have forgotten your password.\nYour password is: $correct_password\nHave a great day!\nMatelook";
    close F;
}

sub create_account{
#
# Creates an account with details supplied
#
    my($full_name, $zID, $password, $email) = @_;
    mkdir "$users_dir/$zID" or die "Could not make dir $users_dir/$zID: $!";
    my $user_file = "$users_dir/$zID/user.txt";
    open F, ">", "$users_dir/$zID/user.txt" or die "Could not open users_dir/$zID/user.txt: $!";
    print F "full_name=$full_name\n";
    print F "zid=$zID\n";
    print F "password=$password\n";
    print F "email=$email\n";
    close F;

    open F, '|-', 'mail', '-s', 'Matelook Account Confirmation', $email or die "Could not send email: $!";
    print F "Hello!\nThanks for registering an account at Matelook!\nYour login details are:\n zID = $zID\n password = $password\nHave a great day!\nMatelook";
    close F;
}

sub verification {
#
# Checks to see if login details are correct
#
    my ($user, $pass) = @_;
    if(-d "$users_dir/$user"){
        open my $p, "$users_dir/$user/user.txt" or die "can not open $users_dir/$user/user.txt: $!";
        while ($line = <$p>){
            if($line =~ /password=(.*)/){
            $correct_password = $1;
                if($pass eq $correct_password){
                    return 1;
                }
            }
        }
    } 

    print ("<div class='alert alert-danger' role='alert'>Incorrect Username or Password!</div>");
    return 0;
}

sub forgot_password{
#
# page to reset password created through bootstrap
#
    return  <<eof
    <form method="POST">
       <div class="container" align=center style="margin-top:25vh">
       <h1>Matelook<small><br>Enter your zID and email below!</small></h1>
           <div style="width:300px; margin-top:25px" align=center>
               <form class="form-horizontal" role="form">
                   <div class="form-group">
                       <label for="zID_forgot" class="col-sm-2 control-label">zID</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                          <input type="text" class="form-control" name="zID_forgot" id="zID_forgot" placeholder="zID">
                      </div>
                   </div>
                   <div class="form-group">
                       <label for="email_forgot" class="col-sm-2 control-label">Email</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="text" class="form-control" name="email_forgot" id="email_forgot" placeholder="Email">
                       </div>
                   </div>
               </form>
           <div align=center>
                   <button type="submit" name="send_password" class="btn btn-primary">Send Password</button>
                   <button type="submit" class="btn btn-primary">Return to Login</button>
           </div>
           </div>
       </div>
    </form>
eof
}

sub signup_page{
#
# signup page if you don't have an account created through bootstrap
#
    return  <<eof
    <form method="POST">
       <div class="container" align=center style="margin-top:10vh">
       <h1>Matelook<small><br>Register your account!</small></h1>
           <div style="width:350px; margin-top:15px" align=center>
               <form class="form-horizontal" role="form">
                   <div class="form-group">
                       <label for="full_name_signup" class="col-sm-2 control-label">Full Name</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                          <input type="text" class="form-control" name="full_name_signup" id="full_name_signup" placeholder="Full Name">
                      </div>
                   </div>
                   <div class="form-group">
                       <label for="zID_signup" class="col-sm-2 control-label">zID</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="text" class="form-control" name="zID_signup" id="zID_signup" placeholder="zID">
                       </div>
                   </div>
                   <div class="form-group">
                       <label for="password_signup" class="col-sm-2 control-label">Password</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="password" class="form-control" name="password_signup" id="password_signup" placeholder="Password">
                       </div>
                   </div>
                   <div class="form-group">
                       <label for="password_confirm_signup" class="col-sm-2 control-label">Confirm Password</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="password" class="form-control" name="password_confirm_signup" id="password_confirm_signup" placeholder="Confirm Password">
                       </div>
                   </div>
                   <div class="form-group">
                       <label for="email_signup" class="col-sm-2 control-label">Email</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="email" class="form-control" name="email_signup" id="email_signup" placeholder="Email">
                       </div>
                   </div>
                   <div class="form-group">
                       <label for="email_confirm_signup" class="col-sm-2 control-label">Confirm Email</label>
                       <div class="col-sm-15" style="margin-bottom:10px">
                           <input type="email" class="form-control" name="email_confirm_signup" id="email_confirm_signup" placeholder="Confirm Email">
                       </div>
                   </div>
               </form>
           <div align=center>
                   <button type="submit" name="create_account" class="btn btn-primary">Create Account</button>
                   <button type="submit" class="btn btn-primary">Return to Login</button>
           </div>
           </div>
       </div>
    </form>
eof
    
}



sub page_header {

#
# HTML placed at the top of every page, includes bootstrap
#
    return <<eof
Content-Type: text/html;charset=utf-8

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Matelook</title>
<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

<!-- Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
<title>Matelook</title>
<link href="matelook.css" rel="stylesheet">
</head>
<body>
eof
}

sub page_trailer {

#
# HTML placed at the bottom of every page
# It includes all supplied parameter values as a HTML comment
# if global variable $debug is set
#

    my $html = "";
    $html .= join("", map("<!-- $_=".param($_)." -->\n", param())) if $debug;
    $html .= end_html;
    return $html;
}

main();