#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_lockout_failed_password_attempts_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure lockout for failed password attempts is configured"
# 
   
deb_ensure_lockout_failed_password_attempts_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""
   
    deb_ensure_lockout_failed_password_attempts_configured_chk()
	{
        echo -e "- Start check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""
        l_faillock_auth="" l_faillock_account="" l_faillock_config=""
        l_auth_tst="" l_account_tst="" l_config_tst=""

        # Verify settings in /etc/pam.d/common-auth
        l_faillock_auth="$(grep -P -- 'pam_faillock.so' /etc/pam.d/common-auth)"

        if [ -n "$l_faillock_auth" ]; then
            if grep -Pq -- '^\h*auth\h+required\h+pam_faillock\.so\h+([^#]*)?preauth' <<< "$l_faillock_auth" && grep -Pq -- '^\h*auth\h+\[default=die\]\h+pam_faillock\.so\h+([^#]*)?authfail' <<< "$l_faillock_auth" && grep -Pq -- '^\h*auth\h+sufficient\h+pam_faillock\.so\h+([^#]*)?authsucc' <<< "$l_faillock_auth"; then
                l_output="$l_output\n- pam_faillock values configured correctly in /etc/pam.d/common-auth:\n$l_faillock_auth"
                l_auth_tst="passed"
            else
                l_output2="$l_output2\n- pam_faillock values NOT configured correctly in /etc/pam.d/common-auth:\n$l_faillock_auth"
            fi
        else
            l_output2="$l_output2\n- No pam_faillock values found in /etc/pam.d/common-auth"
        fi

        # Verify settings in /etc/pam.d/common-account
        l_faillock_account="$(grep -P -- 'pam_faillock.so' /etc/pam.d/common-account)"

        if [ -n "$l_faillock_auth" ]; then
            if grep -Pq -- '^\h*account\h+required\h+pam_faillock.so([^#]*)?' <<< "$l_faillock_account"; then
                l_output="$l_output\n- pam_failock values configured correctly in /etc/pam.d/common-account:\n$l_faillock_account"
                l_account_tst="passed"
            else
                l_output2="$l_output2\n- pam_failock values NOT configured correctly in /etc/pam.d/common-account:\n$l_faillock_account"
            fi
        else
            l_output2="$l_output2\n- No pam_faillock values found in /etc/pam.d/common-account"
        fi

        # Verify settings in /etc/security/faillock.conf
        l_faillock_config="$(grep -P -- '^\s*(deny|fail_interval|unlock_time)\b' /etc/security/faillock.conf)"

        if [ -n "$l_faillock_config" ]; then
            if grep -Pq -- '^\h*deny\h*=\h*[1-4]\b' <<< "$l_faillock_config" && grep -Pq -- '^\h*fail_interval\h*=\h*(900|[1-8][0-9]{2}|[1-9][0-9]|[1-9])\b' <<< "$l_faillock_config" && grep -Pq -- '^\h*unlock_time\h*=\h*(600|[1-5][0-9]{2}|[1-9][0-9]|[1-9])\b' <<< "$l_faillock_config"; then
                l_output="$l_output\n- lockout values configured correctly in /etc/security/faillock.conf:\n$l_faillock_config"
                l_config_tst="passed"
            else
                l_output2="$l_output2\n- lockout values NOT configured correctly in /etc/security/faillock.conf:\n$l_faillock_config"
            fi
        else
            l_output2="$l_output2\n- No pam_faillock values found in /etc/security/faillock.conf"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }
   
    deb_ensure_lockout_failed_password_attempts_configured_fix()
	{
        echo -e "- Start remediation - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"

        # Update the entries in /etc/pam.d/common-auth
        if [ "$l_auth_tst" != "passed" ]; then
            echo -e "- Updating /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
            if ! grep -Pqs -- '^\h*auth\h+required\h+pam_faillock\.so\h+([^#]*)?preauth' /etc/pam.d/common-auth; then
                if grep -Ps '^\h*auth\h+required\h+pam_faillock\.so' /etc/pam.d/common-auth; then
                    echo -e "- Adding 'preauth' value to 'auth required                        pam_faillock.so' line in /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(auth\s+required\s+pam_faillock\.so)([^#]+\s*)?(#.*)?$/\2\3 preauth \4/' /etc/pam.d/common-auth
                else
                    if grep -Pqs "^\h*#\h*here\h*are\h*the\h*per-package\h*modules\h*\(the\h*\"Primary\"\h*block\)" /etc/pam.d/common-auth; then
                        echo -e "- Adding 'auth    required                        pam_faillock.so preauth' to /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*#\s*here\s*are\s*the\s*per-package\s*modules\s*\(the\s*\"Primary\"\s*block\)/a auth    required                        pam_faillock.so preauth' /etc/pam.d/common-auth
                    else
                        echo -e "- Could not safely insert 'auth    required                        pam_faillock.so preauth' into /etc/pam.d/common-auth\n- This entry should be manually configured" | tee -a "$LOG" 2>> "$ELOG"
                        l_test="manual"
                    fi
                fi
            fi

            if ! grep -Pqs -- '^\h*auth\h+\[default=die\]\h+pam_faillock\.so\h+([^#]*)?authfail' /etc/pam.d/common-auth; then
                if grep -Ps '^\h*auth\h+\[default=die\]\h+pam_faillock\.so' /etc/pam.d/common-auth; then
                    echo -e "- Adding 'authfail' value to 'auth [default=die]                        pam_faillock.so' line in /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(auth\s+\[default=die\]\s+pam_faillock\.so)([^#]+\s*)?(#.*)?$/\2\3 authfail \4/' /etc/pam.d/common-auth
                else
                    if grep -Pqs "^\h*#\h+here's\h+the\h+fallback\h+if\h+no\h+module\h+succeeds" /etc/pam.d/common-auth; then
                        echo -e "- Adding 'auth    [default=die]                   pam_faillock.so authfail' to /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri "/^\s*#\s+here's\s+the\s+fallback\s+if\s+no\s+module\s+succeeds/i auth    [default=die]                   pam_faillock.so authfail" /etc/pam.d/common-auth
                    else
                        echo -e "- Could not safely insert 'auth    [default=die]                   pam_faillock.so authfail' into /etc/pam.d/common-auth\n- This entry should be manually configured" | tee -a "$LOG" 2>> "$ELOG"
                        l_test="manual"
                    fi
                fi
            fi

            if ! grep -Pqs -- '^\h*auth\h+sufficient\h+pam_faillock\.so\h+([^#]*)?authsucc' /etc/pam.d/common-auth; then
                if grep -Ps '^\h*auth\h+sufficient\h+pam_faillock\.so' /etc/pam.d/common-auth; then
                    echo -e "- Adding 'authsucc' value to 'auth    sufficient                      pam_faillock.so' line in /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(auth\s+sufficient\s+pam_faillock\.so)([^#]+\s*)?(#.*)?$/\2\3 authsucc \4/' /etc/pam.d/common-auth
                else
                    if grep -Pqs "^\h*auth\h*\[default=die\]\h*pam_faillock\.so" /etc/pam.d/common-auth; then
                        echo -e "- Adding 'auth    sufficient                      pam_faillock.so authsucc' to /etc/pam.d/common-auth" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*auth\s*\[default=die\]\s*pam_faillock\.so/a auth    sufficient                      pam_faillock.so authsucc' /etc/pam.d/common-auth
                    else
                        echo -e "- Could not safely insert 'auth    sufficient                      pam_faillock.so authsucc' into /etc/pam.d/common-auth\n- This entry should be manually configured" | tee -a "$LOG" 2>> "$ELOG"
                        l_test="manual"
                    fi
                fi
            fi
        fi

        # Update the entry in /etc/pam.d/common-account
        if [ "$l_account_tst" != "passed" ]; then
            echo -e "- Updating /etc/pam.d/common-account" | tee -a "$LOG" 2>> "$ELOG"
            if grep -Pqs "^\h*#\h*end\h*of\h*pam-auth-update\h*config" /etc/pam.d/common-account; then
                echo -e "- Adding 'account     required      pam_faillock.so' to /etc/pam.d/common-account" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri '/^\s*#\s*end\s*of\s*pam-auth-update\s*config/i account     required      pam_faillock.so' /etc/pam.d/common-account
            else
                echo -e "- Could not safely insert 'account     required      pam_faillock.so' into /etc/pam.d/common-account\n- This entry should be manually configured" | tee -a "$LOG" 2>> "$ELOG"
                l_test="manual"
            fi
        fi

         # Update the entries in /etc/security/faillock.conf
        if [ "$l_config_tst" != "passed" ]; then
            echo -e "- Updating /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
            if ! grep -Pq -- '^\h*deny\h*=\h*[1-4]\b' /etc/security/faillock.conf; then
                if grep -Pqs '^\h*(#\h*)?deny\h*=' /etc/security/faillock.conf; then
                    echo -e "- Updating 'deny =' value in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(deny\s*=)(\s*\S+\b)(.*)?$/\2 4 \4/' /etc/security/faillock.conf
                else
                    if grep -Eq "^\h*#\h*The\h*default\h*is\h*3\." /etc/security/faillock.conf; then
                        echo -e "- Adding 'deny = 4' to /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*#\s*The\s*default\s*is\s*3\./a deny = 4' /etc/security/faillock.conf
                    else
                        echo -e "- Inserting 'deny = 4' to end of /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        echo "deny = 4" >> /etc/security/faillock.conf
                    fi
                fi
            else
                echo -e "- 'deny =' value set correctly in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
            fi

            if ! grep -Pq -- '^\h*fail_interval\h*=\h*(900|[1-8][0-9]{2}|[1-9][0-9]|[1-9])\b' /etc/security/faillock.conf; then
                if grep -Pqs '^\h*(#\h*)?fail_interval\h*=' /etc/security/faillock.conf; then
                    echo -e "- Updating 'fail_interval =' value in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(fail_interval\s*=)(\s*\S+\b)(.*)?$/\2 900 \4/' /etc/security/faillock.conf
                else
                    if grep -Eq "^\h*#\h*The\h*default\h*is\h*900\h*\(15\h*minutes\)\." /etc/security/faillock.conf; then
                        echo -e "- Adding 'fail_interval = 900' to /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*#\s*The\s*default\s*is\s*900\s*\(15\s*minutes\)\./a fail_interval = 900' /etc/security/faillock.conf
                    else
                        echo -e "- Inserting 'fail_interval = 900' to end of /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        echo "fail_interval = 900" >> /etc/security/faillock.conf
                    fi
                fi
            else
                echo -e "- 'fail_interval =' value set correctly in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
            fi

            if ! grep -Pq -- '^\h*unlock_time\h*=\h*(600|[1-5][0-9]{2}|[1-9][0-9]|[1-9])\b' /etc/security/faillock.conf; then
                if grep -Pqs '^\h*(#\h*)?unlock_time\h*=' /etc/security/faillock.conf; then
                    echo -e "- Updating 'unlock_time =' value in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(unlock_time\s*=)(\s*\S+\b)(.*)?$/\2 600 \4/' /etc/security/faillock.conf
                else
                    if grep -Eq "^\h*#\h*The\h*default\h*is\h*600\h*\(10\h*minutes\)\." /etc/security/faillock.conf; then
                        echo -e "- Adding 'unlock_time = 600' to /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*#\s*The\s*default\s*is\s*600\s*\(10\s*minutes\)\./a unlock_time = 600' /etc/security/faillock.conf
                    else
                        echo -e "- Inserting 'unlock_time = 600' to end of /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                        echo "unlock_time = 600" >> /etc/security/faillock.conf
                    fi
                fi
            else
                echo -e "- 'unlock_time =' value set correctly in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
            fi
        fi

        echo -e "- End remediation - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    deb_ensure_lockout_failed_password_attempts_configured_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_lockout_failed_password_attempts_configured_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_lockout_failed_password_attempts_configured_chk
                if [ "$?" = "101" ] ; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
            fi
        fi
    fi
	
	# Set return code and return
	case "$l_test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo "Recommendation \"$RNA\" Something went wrong - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}