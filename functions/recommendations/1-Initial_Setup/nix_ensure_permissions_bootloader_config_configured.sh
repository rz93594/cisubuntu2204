#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_permissions_bootloader_config_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/15/20    Recommendation "Ensure permissions on bootloader config are configured"
# Eric Pinnell       04/19/22    Modified to correct possible errors and enhance logging
# Justin Brown       07/31/2022  Updated to add logging and validation to _fix function
#

ensure_permissions_bootloader_config_configured()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""

   # Set grubfile vars 
   l_grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl '^\h*(kernelopts=|linux|kernel)' {} \;)
	l_grubdir=$(dirname "$l_grubfile")
	
	ensure_permissions_bootloader_config_configured_chk()
	{
		echo -e "- Start check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
		
		l_tst1="" l_tst2="" l_tst3="" l_tst4="" l_output="" l_output2="" l_output3="" l_output4=""

		stat -c "%a" "$l_grubfile" | grep -Pq '^\h*[0-7]00$' && l_tst1=pass
		l_output="Permissions on \"$l_grubfile\" are \"$(stat -c "%a" "$l_grubfile")\""

		stat -c "%u:%g" "$l_grubfile" | grep -Pq '^\h*0:0$' && l_tst2=pass
		l_output2="\"$l_grubfile\" is owned by \"$(stat -c "%U" "$l_grubfile")\" and belongs to group \"$(stat -c "%G" "$l_grubfile")\""

		if [ -f "$l_grubdir/user.cfg" ]; then
			stat -c "%a" "$l_grubdir/user.cfg" | grep -Pq '^\h*[0-7]00$' && l_tst3=pass
			l_output3="Permissions on \"$l_grubdir/user.cfg\" are \"$(stat -c "%a" "$l_grubdir/user.cfg")\""

			stat -c "%u:%g" "$l_grubdir/user.cfg" | grep -Pq '^\h*0:0$' && l_tst4=pass
			l_output4="\"$l_grubdir/user.cfg\" is owned by \"$(stat -c "%U" "$l_grubdir/user.cfg")\" and belongs to group \"$(stat -c "%G" "$l_grubdir/user.cfg")\""
		else
			l_tst3=pass
			l_tst4=pass
		fi

		if [ "$l_tst1" = "pass" ] && [ "$l_tst2" = "pass" ] && [ "$l_tst3" = "pass" ] && [ "$l_tst4" = "pass" ]; then
			echo -e "- PASSED" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo "- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output2" ] && echo "- $l_output2" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output3" ] && echo "- $l_output3" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output4" ] && echo "- $l_output4" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "- FAILED"  | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo "- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output2" ] && echo "- $l_output2" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output3" ] && echo "- $l_output3" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output4" ] && echo "- $l_output4" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	ensure_permissions_bootloader_config_configured_fix()
	{
		echo -e "- Start remediation - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
      l_rem1="" l_rem2="" l_rem3="" l_rem4=""

		if [ -f "$l_grubdir"/user.cfg ]; then
         echo -e "- Setting permissions on $l_grubdir/user.cfg" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/user.cfg
			chmod og-rwx "$l_grubdir"/user.cfg

         if stat -c "%a" "$l_grubdir/user.cfg" | grep -Pq '^\h*[0-7]00$' && stat -c "%u:%g" "$l_grubdir/user.cfg" | grep -Pq '^\h*0:0$'; then
            l_rem1=pass
         fi
      else
         l_rem1=na         
		fi

		if [ -f "$l_grubdir"/grubenv ]; then
         echo -e "- Setting permissions on $l_grubdir/grubenv" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grubenv
			chmod og-rwx "$l_grubdir"/grubenv

         if stat -c "%a" "$l_grubdir/grubenv" | grep -Pq '^\h*[0-7]00$' && stat -c "%u:%g" "$l_grubdir/grubenv" | grep -Pq '^\h*0:0$'; then
            l_rem2=pass
         fi
      else
         l_rem2=na    
		fi
		if [ -f "$l_grubdir"/grub.cfg ]; then
         echo -e "- Setting permissions on $l_grubdir/grub.cfg" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grub.cfg
			chmod og-rwx "$l_grubdir"/grub.cfg

         if stat -c "%a" "$l_grubdir/grub.cfg" | grep -Pq '^\h*[0-7]00$' && stat -c "%u:%g" "$l_grubdir/grub.cfg" | grep -Pq '^\h*0:0$'; then
            l_rem3=pass
         fi
      else
         l_rem3=na
		fi
		if [ -f "$l_grubdir"/grub.conf ]; then
         echo -e "- Setting permissions on $l_grubdir/grub.conf" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grub.conf
			chmod og-rwx "$l_grubdir"/grub.conf

         if stat -c "%a" "$l_grubdir/grub.conf" | grep -Pq '^\h*[0-7]00$' && stat -c "%u:%g" "$l_grubdir/grub.conf" | grep -Pq '^\h*0:0$'; then
            l_rem4=pass
         fi
      else
         l_rem4=na
		fi

      # Check remediation and set status
      if { [ "$l_rem1" = "pass" ] || [ "$l_rem1" = "na" ]; }  && { [ "$l_rem2" = "pass" ] || [ "$l_rem2" = "na" ]; } && { [ "$l_rem3" = "pass" ] || [ "$l_rem3" = "na" ]; } && { [ "$l_rem4" = "pass" ] || [ "$l_rem2" = "na" ]; }; then
         test=remediated
      fi

		echo  -e "- End remediation - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	ensure_permissions_bootloader_config_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		if grep -Pq -- "^\h*\/boot\/efi\/" <<< "$l_grubdir"; then
			test="manual"
		else
			ensure_permissions_bootloader_config_configured_fix
			ensure_permissions_bootloader_config_configured_chk
			if [ "$?" = "101" ]; then
				[ "$test" != "failed" ] && test="remediated"
			else
				test="failed"
			fi
		fi
	fi
	
	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
		passed)
			echo -e "- Result - No remediation required\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo -e "- Result - successfully remediated\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo -e "- Result - requires manual remediation\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo -e "- Result - Recommendation is non applicable\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo -e "- Result - remediation failed\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}