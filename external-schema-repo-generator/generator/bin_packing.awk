# ============LICENSE_START=======================================================
# OOM
# ================================================================================
# Copyright (C) 2020-2021 Nokia. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#      http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============LICENSE_END=========================================================

function first_fit(v, file) {
    # find first bin that can accomodate the volume
    for (i=1; i<=n; ++i) {
        if (b[i] > v) {
            b[i] -= v
            bc[i]++
            cmd="mkdir -p "tmpLocation"/"schema"-subdir-"i"/OpenAPI"
            system(cmd)
            cmd="mv "file" " tmpLocation"/"schema  "-subdir-" i "/OpenAPI"
            system(cmd)
            return
        }
    }
    # no bin found, create new bin
    if (i > n) {
        b[++n] = c - v
        bc[n]++
        cmd="mkdir -p "tmpLocation"/"schema"-subdir-"n"/OpenAPI"
        system(cmd)
        cmd="mv "file" " tmpLocation"/"schema  "-subdir-"n"/OpenAPI"
        system(cmd)
    }
    return
}
BEGIN{ if( (c+0) == 0) exit }
{ first_fit($1,$2) }
END { print "REPORT:"
    print "Created",n,"directories"
    for(i=1;i<=n;++i) {
	    print "- "tmpLocation"/"schema"-subdir-"i,":", c-b[i],"bytes",bc[i],"files"
    }
}
