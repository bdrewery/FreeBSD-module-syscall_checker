This module checks all system calls in the running kernel to detect if they have been hooked into. Thus revealing a possible rootkit.


# Usage
env PATH=/bin:/sbin:/usr/sbin:/usr/bin /bin/sh -c "make clean && make && make load && make unload && make clean"

# Example output

<pre>
- Modified System Calls -
number name                           new-addr
------ ---------                      --------
98     connect                        0xc92d95f3
104    bind                           0xc92d9682
- End -
</pre>
