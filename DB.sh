#!/usr/bin/bash
function main {
	function create {
		echo "Enter The Name Of Database"
		read name
		if [ -z $name ]; then
			while [ -z $name ]; do
				echo "Please Enter A Database Name"
				read name
				if [ -d $name ] && [ ! -z $name ]; then
					while [ -d $name ]; do
						echo "This Database Is Exist, Please Enter Another Database Name12"
						read name
						if [ -z $name ]; then
							while [ -z $name ]; do
								echo "Please Enter A Database Name5"
								read name
								if [ ! -d $name ]; then
									mkdir $name
									echo "Database $name Created Successfully"
									break
								fi
							done
						elif [ ! -d $name ]; then
							mkdir $name
							echo "Database $name Created Successfully"
							break
						fi
					done
				else
					mkdir $name
					echo "Database $name Created Successfully"
					break
				fi
			done

		elif [ -d $name ]; then
			while [ -d $name ] && [ ! -z $name ]; do
				echo "This Database Is Exist, Please Enter A Database Name"
				read name
				if [ -z $name ]; then
					while [ -z $name ]; do
						echo "Please Enter A Database Name"
						read name
						if [ -d $name ] && [ ! -z $name ]; then
							while [ -d $name ] && [ ! -z $name ]; do
								echo "This Database Is Exist, Please Enter Another Database Name"
								read name
								if [ ! -d $name ] && [ ! -z $name ]; then
									mkdir $name
									echo "Database $name Created Successfully"
									break
								fi
							done
						elif [ ! -z $name ] && [ ! -d $name ]; then
							mkdir $name
							echo "Database $name Created Successfully"
							break 4
						fi
					done
				elif [ ! -d $name ]; then
					mkdir $name
					echo "Database $name Created Successfully"
					break
				fi
			done
		else
			mkdir $name
			echo "Database $name Created Successfully"
		fi
	}

	function list {
		if [[ $(ls -l | grep ^d | wc -l) -eq 0 ]]; then
			echo "You Don't Have Any Databases yet"
		else
			ls -d */ | cut -f1 -d'/'
		fi
	}

	function connect {
		function testInput {
			re='^[0-9]+$'
			if ! [[ $1 =~ $re ]]; then
				type="string"
			else
				type="int"
			fi
			if [[ "$type" == "$2" ]]; then
				return 1
			else
				return 0
			fi
		}
		function checkPk {
			fieldNumber=$(awk -v RS=';' "/pk/"'{print NR}' $1)
			pksValues=$(sed '1d' $1 | cut -d ";" -f $fieldNumber)
			re='^[0-9]+$'
			for value in $pksValues; do
				if ! [[ $2 =~ $re ]]; then
					# type="string"
					if [ $2 = $value ]; then
						return 0
					fi
				else
					# type="int"
					if [ $2 -eq $value ]; then
						return 0
					fi
				fi
			done
			return 1
		}
		################## List Databases #######################
		if [[ $(ls -l | grep ^d | wc -l) -eq 0 ]]; then
			echo "You Don't Have Any Databases Yet, Please Create One First"
		else
			printf "Please Select From Avilable Databases:\n"
			ava=$(ls -d */ | cut -f1 -d'/')
			select d in $ava; do
				test -n "$d" && break
				echo "Please Select From Avilable Databases"
			done
			cd "$d"
			echo "You Are Now Connected To $d"

			################# Create Tables ##############################
			function createTable {
				function tableName {
					echo "Enter Table Name"
					read tName
					if [ -f $tName ] && [ ! -z $tName ]; then
						while [ -f $tName ]; do
							echo "Table Already Exist, Pleses Enter Another Name"
							read tName
							if [ -z $tName ]; then
								while [ -z $tName ]; do
									echo "Please Enter A Name"
									read tName
									if [ -f $tName ] && [ ! -z $tName ]; then
										echo "Table Already Exist"
										read tName
									elif [ ! -f $tName ]; then
										break
									fi
								done
							fi
						done
					elif [ -z $tName ]; then
						while [ -z $tName ]; do
							echo "Pleses Enter A Valid Name"
							read tName
							if [ -f $tName ] && [ ! -z $tName ]; then
								echo "Table Already Exist"
								read tName
							elif [ ! -z $tName ] && [ ! -f $tName ]; then
								break
							fi
						done
					fi
				}
				function handelColumn {
					echo "Enter number of columns"
					read colNum
					if [ -z $colNum ]; then
						while [ -z $colNum ]; do
							if [ -z $colNum ]; then
								echo "Please Enter A Number"
								read colNum
							elif [ ! -z $colNum ]; then
								break
							fi
						done
					else
						testInput $colNum "int"
						if [ $? -eq 0 ]; then
							echo "Please enter number of columns in integer type"
							read colNum
						fi
						touch $tName
						typeset -i i=0
						columns=""
						while [ $i -lt $colNum ]; do
							echo "Enter column Name"
							read colName
							echo "Select column type"
							select type in "int" "string"; do
								colType=$type
								break
							done
							##### read colType
							if [ -z $pk ]; then
								echo "Primarykey?"
								select answer in "yes" "no"; do
									case $REPLY in
									1)
										pk=$colName
										colName+="(pk)"
										break
										;;
									2) break ;;
									*) echo " Please Select from yes or no " ;;
									esac
								done
							fi
							columns+="$colName:$colType;"
							i=$i+1
						done
						printf $columns >>$tName
					fi
				}
				tableName
				handelColumn
			}

			############## List Tables ###################
			function listTables {
				if [[ $(ls -l | grep ^- | wc -l) -eq 0 ]]; then
					echo "There Is No Tables To List"
				else
					ls -l | grep ^- | awk -F' ' '{print $9}' | cut -f1 -d'.'
				fi
			}
			############## Drop Tables ##################
			function dropTable {
				if [[ $(ls -l | grep ^- | wc -l) -eq 0 ]]; then
					echo "There Is No Tables To Drop"
				else
					select t in *; do
						test -n "$t" && break
						echo "Please Select From Avilable Databases"
					done
					rm $t
					echo "Table $t Droped Successfully"
				fi
			}

			############### Insert Function ####################
			function insertT {
				select t in *; do
					test -n "$t"
					echo "Please Select From Avilable Tables"
					insertHandel $t
					break
				done
			}
			function insertHandel {
				typeset -i i=1
				colName=$(cut -d";" -f $i $1 | cut -d":" -f 1 | head -1)
				colType=$(cut -d";" -f $i $1 | cut -d":" -f 2 | head -1)
				field=''
				while [[ -n $colName ]]; do
					echo "Enter Value of $colName"
					read value
					if [ -z $value ]; then
						until [ ! -z $value ]; do
							echo "Please Enter A Value"
							read value
						done
					fi
					testInput $value $colType
					if [ $? -eq 1 ]; then
						field+="$value;"
					else
						echo "Somthing Wrong!"
						insertT
					fi
					echo $testPk
					checkPk $1 $value
					if [ $? -eq 0 ]; then
						echo "this value exist in pk column!"
						insertT
					fi
					i=$i+1
					colName=$(cut -d";" -f $i $1 | cut -d":" -f 1 | head -1)
					colType=$(cut -d";" -f $i $1 | cut -d":" -f 2 | head -1)
				done
				printf "\n" >>$1
				printf "$field" >>$1
				printf "\n" >>$1

			}

			############### Select Function ######################
			function selectT {
				select t in *; do
					test -n "$t" && break
					echo "Please Select From Avilable Databases"
				done

				############## Options #################
				function selectOptions {
					select option in "Choose 1 To Select All" "Choose 2 To Back"; do
						case $REPLY in
						1)
							column -t -s ';' $t
							;;
						2)
							cd ..
							connect
							;;
						*)
							echo "Please Select From Above Options"
							;;
						esac
					done
				}

				selectOptions
			}

			############## Delete ###################
			function delete {
				select t in *; do
					test -n "$t" && break
					echo "Please Select From Avilable Tables"
				done
				function deleteHandel {
					echo -e "Enter Condition Column name: \c"
					read field
					if [ -z $field ]; then
						until [ ! -z $field ]; do
							echo "Please Enter A Column Name"
							read field
						done
					fi
					fid=$(awk -v RS=';' "/$field/ "'{print NR}' $t)
					if [ -z $fid ]; then
						echo "Not Found"
					else
						echo -e "Enter Condition Value: \c"
						read val
						if [ -z $val ]; then
							until [ ! -z $val ]; do
								echo "Please Enter A Value"
								read val
							done
						fi
						res=$(cut -d ";" -f $fid $t 2>/dev/null | awk "/$val/ "'{print NR}')
						if [[ -z $res ]]; then
							echo "Value Not Found"
							delete
						else
							echo $res
							sed -i ''$res'd' $t 2>/dev/null
							echo "Row Deleted Successfully"
							connect
						fi
					fi
				}
				deleteHandel
			}
			############## Update ###################
			function update {
				function ListUpdate {
					select t in *; do
						test -n "$t" && break
						echo "Please Select From Avilable Tables"
					done
					function updateHandel {
						echo "Enter condition column "
						read colName
						if [ -z $colName ]; then
							until [ ! -z $colName ]; do
								echo "Please Enter A Column Name"
								read colName
							done
						fi
						fieldNumber=$(awk -v RS=';' "/$colName/ "'{print NR}' $t)

						echo "enter conditon value "
						read value
						if [ -z $value ]; then
							until [ ! -z $value ]; do
								echo "Please Enter A Value"
								read value
							done
						fi
						searchResult=$(cut -d ";" -f $fieldNumber $t 2>/dev/null | awk "/$value/"'{print NR}')

						echo "Enter update col : "
						read colUpdate
						if [ -z $colUpdate ]; then
							until [ ! -z $colUpdate ]; do
								echo "Please Enter The Column You Want To Update"
								read colUpdate
							done
						fi
						updateNum=$(awk -v RS=';' "/$colUpdate/ "'{print NR}' $t)

						colType=$(cut -d";" -f $updateNum $t | cut -d":" -f 2 | head -1)
						echo "enter new value"
						read newValue
						if [ -z $newValue ]; then
							until [ ! -z $newValue ]; do
								echo "Please Enter Your New Value"
								read newValue
							done
						fi
						testInput $newValue $colType
						if [ $? -eq 0 ]; then
							echo "Wrong Type"
							update
						fi
						checkPk $t $newValue
						if [ $? -eq 0 ]; then
							echo "pk exist"
							update
						fi
						oldValue=$(awk 'BEGIN{FS=";"} { if(NR=="'$searchResult'"){print $'$updateNum';}}' $t)
						sed -i ''$searchResult's/'$oldValue'/'$newValue'/g' $t 2>>/dev/null
					}

					updateHandel
				}

				select x in "Choose 1 To Choose From Tables" "Choose 2 To Back"; do
					case $REPLY in
					1)
						ListUpdate
						;;
					2)
						cd ..
						connect
						;;
					*)
						echo "Please Select From Avilable Option"
						;;
					esac
				done

			}

			select o in "Choose 1 to Create Table" "Choose 2 List Tables" "Choose 3 To Drop Table" "Choose 4 To Insert Into Table" "Choose 5 To Select From Table" "Choose 6 To Delete From Table" "Choose 7 To Update Table" "Choose 8 To Back"; do
				case $REPLY in
				1)
					createTable
					;;
				2)
					listTables
					;;

				3)
					dropTable
					;;
				4)
					insertT
					;;
				5)
					selectT
					;;

				6)
					delete
					;;
				7)
					update
					;;
				8)
					cd ..
					main
					;;
				*)
					echo "Sorry $REPLY Is Not One Of The Options"
					;;
				esac
			done

		fi

	}

	function dropDB {
		if [[ $(ls -l | grep ^d | wc -l) -eq 0 ]]; then
			echo "There Is No Databases To Be Deleted"
		else
			ava=$(ls -d */ | cut -f1 -d'/')
			select d in $ava; do
				test -n "$d" && break
				echo "Please Select From Avilable Databases"
			done
			rm -r $d
			echo "Database $d Droped Successfully"
		fi
	}

	PS3="select from the Above: "
	select c in "Choose 1 To Create Database" "Choose 2 To List Databases" "Choose 3 To Connect To Database" "Choose 4 To Drop Database"; do
		case $REPLY in
		1)
			create
			;;
		2)
			list
			;;
		3)
			connect
			;;
		4)
			dropDB
			;;
		*)
			echo sorry $REPLY is not one of the options
			;;
		esac
	done
}

#### run script ########
main
