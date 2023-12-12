#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_reuse_limited.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure password reuse is limited"
# 
   
deb_ensure_password_reuse_limited()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""
   
    deb_ensure_password_reuse_limited_chk()
	{
        echo -e "- Start check - Ensure password reuse is limited" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""
        file="/etc/pam.d/common-password"

        if grep -Pqs '^\h*password\h+\[success=\S\h+default=ignore\]\h+pam_unix\.so(\h+[^#]+\h+)?remember=([5-9]|[1-9][0-9]+)\b' "$file"; then
            l_output="- Password reuse is properly configured in $file:\n  $(grep -Pqs '^\h*password\h+\[success=1\h+default=ignore\]\h+pam_unix\.so(\h+[^#]+\h+)?remember=([5-9]|[1-9][0-9]+)\b' $file)"
        else
            l_output2="- Password reuse is NOT properly configured in $file"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password reuse is limited" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password reuse is limited" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }
   
    deb_ensure_password_reuse_limited_fix()
	{
        echo -e "- Start remediation - Ensure password reuse is limited" | tee -a "$LOG" 2>> "$ELOG"

        if grep -Pqs '^\h*password\h+\[success=\S\h+default=ignore\]\h+pam_unix\.so(\h+[^#]+\h+)?remember=' "$file"; then
            echo -e "- Updating 'remember=' value in $file" | tee -a "$LOG" 2>> "$ELOG"
			sed -ri 's/^\s*(#\s*)?(password\s+\[success=\S\s+default=ignore\]\s+pam_unix\.so\s+)([^#]+\s+)?(remember=)(\S+\b)(.*)?$/\2\3\45 \6/' "$file"
		elif grep -Ps '^\h*password\h+\[success=\S\h+default=ignore\]\h+pam_unix\.so' "$file" | grep -vq 'remember='; then
            echo -e "- Adding 'remember=5' value to $file" | tee -a "$LOG" 2>> "$ELOG"
			sed -ri 's/^\s*(#\s*)?(password\s+\[success=\S\s+default=ignore\]\s+pam_unix\.so\s+)([^#]+\s*)?(#.*)?$/\2\3 remember=5\4/' "$file"
		else
			if grep -Eq "^\s*#\s+end\s+of\s+pam-auth-update\s+config" "$file"; then
                echo -e "- Adding 'password    [success=2 default=ignore]      pam_unix.so remember=5' to $file" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri '/^\s*#\s+end\s+of\s+pam-auth-update\s+config/ i password    [success=2 default=ignore]      pam_unix.so remember=5' "$file"
			else
                echo -e "- Inserting 'password    [success=2 default=ignore]      pam_unix.so remember=5' to end of $file" | tee -a "$LOG" 2>> "$ELOG"
				echo "password    [success=2 default=ignore]      pam_unix.so remember=5" >> "$file"
			fi
		fi
        
        echo -e "- End remediation - Ensure password reuse is limited" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    deb_ensure_password_reuse_limited_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_reuse_limited_fix
            deb_ensure_password_reuse_limited_chk
            if [ "$?" = "101" ] ; then
                [ "$l_test" != "failed" ] && l_test="remediated"
            else
                l_test="failed"
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