#!/bin/bash

# Atividade 3.4 - Simule o funcionamento de um fórum público por 3 meses...
#
# 
#

## Usuários

## Para esta simulação, teremos os seguintes usuários divididos em duas classes:
## a 1ª, para atender os padrões de comportamento solicitados
## a 2ª, para atender o copartilhamento de HOST 
#
## Classe 1
#
# Pioneiro    : USER_0 - Criador do fórum, principal interessado em impulsionar sua utilização
# Entusiasta  : USER_1 - Usuário ativo, com perfil de moderador e suas interações são relevantes 
# Curioso     : USER_2 - Lê o chat com regularidade mas não interage       
# Regular     : USER_3 - Usuário ativo e suas interações são normais 
# Newbie      : USER_4 - Usuário com bom nível de interação mas participações simples
# Troll       : USER_5 - Usuário ativo mas suas interações são consideradas trolagens
#
## Classe 2
#
# QualquerUm    : USER_6 - Usuário comum para compartilhar host
# QualquerDois  : USER_7 - Usuário comum para compartilhar host
# QualquerTres  : USER_8 - Usuário comum para compartilhar host


### Tipos de Operações para postagens
#
## Tipo de Perguntas
# 21   - troll
# 22   - trivial
# 23   - simples
# 24   - dificil
#
## Tipo de Respostas
#
# 31   - troll
# 32   - correta
# 33   - incorreta
# 34   - parcial
# 35   - complementar
# 36   - correção





############################## Àrea de constantes ############################## 

declare -r SIX_HOUR=21600000        # Quantidade de milisegundos em seis horas
declare -r TWELVE_HOURS=43200000    # Quantidade de milisegundos em doze horas
declare -r DAY=86400000             # Quantidade de milisegundos em um dia

############################## Àrea de variáveis ############################## 

declare -a USUARIOS=(Pioneiro Entusiasta Curioso Regular Newbie Troll Qualquer1 Qualquer2 Qualquer3)
declare -a HOSTS=(8330 8331 8332 8333 8334 8335)
declare -a KEYS     # Array auxiliar do processo de geração de chaves
declare -a PUBKEY   # Array com as chaves públicas
declare -a PRIKEY   # Array com as chaves privadas
declare -a HOSTS    # Array com as portas dos hosts
declare -a BLOCKEDS # Array para guarda temporária dos blocos bloqueados
declare -a ASKS     # Array para guarda temporária dos blocos para interação
declare -i EPOCH    # Tempo base da simulação
declare -i TEMPO    # Base temporal para a simulação
declare -i HOST     # Índice do array HOSTS, indica o host a ser utilizado

############################## Área de funções ############################## 

determinar_porta(){

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Determina a porta utilizada pelo usuário passado no parâmetro posicinal $1
    # e a registra na variável global HOST.
    #
    # É uma atividade operacional da simulação


    k=${#HOSTS[@]}
    
    z=$(( $k - 1 ))

    if [[ $1 < $k ]]     # são usuários da classe 1
    then
        HOST=$1
    else                 # são usuários da classe 2
        HOST=$(($[$1%$z]))
        if [[ $HOST = 0 ]]
        then
            HOST=5
        fi
    fi
}


enviar_atualizacao() {

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Sincroniza a cadeia do nó utilizado pelo usuário $1 enviando suas atualizações
    # para cada um de seus vizinhos.
    #
    # É uma atividade operacional da simulação


    determinar_porta $1

    for I in ${HOSTS[*]}
    do
        if [[ ${HOSTS[$HOST]} = ${I} ]] # esse é o host do usuário $1
        then
            continue
        else
            freechains --host=localhost:${HOSTS[$HOST]} peer localhost:${I} send '#chat'
        fi
    done

}

#////////////////////////////////////////////////////////////////////

buscar_atualizacao() {

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Sincroniza a cadeia do nó utilizado pelo usuário $1 buscando as atualizações de
    # cada um de seus vizinhos.
    #
    # É uma das interações simuladas no script


    determinar_porta $1

    for I in ${HOSTS[*]}
    do
        if [[ ${HOSTS[$HOST]} = ${I} ]]
        then
            continue
        else
            freechains --host=localhost:${HOSTS[$HOST]} peer localhost:${I} recv '#chat'
        fi
    done
}

#////////////////////////////////////////////////////////////////////

saltar_tempo() {   

    ##########################
    ####  $1 o timestamp  ####  
    ##########################

    # Simula a passagem do tempo dentro da simulação e mantém todos os nós sincronizados.
    # Definindo a data e hora do fórum para a fornecida no parâmetro $1
    #
    # É uma atividade operacional da simulação

    for I in ${HOSTS[*]}
    do
        freechains-host --port=${I} now $1
    done
}

#////////////////////////////////////////////////////////////////////

viral() {
    
    ###############################
    ####  $1 hash do bloco     ####    
    ###############################

    # Simula o comportamento do fórum frente a uma postagem que viraliza fazendo com que todos os
    # usuários executem like ou dislike no bloco informado em $1.
    #
    # É uma das interações simuladas no script


    OP=$(($RANDOM%3))                   # Define se o viral será like (OP=1), dislike  (OP=2) ou neutro (OP=0)
    SALTAR=$(( $(($RANDOM%4)) / 3 ))    # Dosa a possibilidade de ocorrerem postagens virais

    if [[ $SALTAR = 0 || $OP = 0  ]]    # $1 não viralizou
    then
        return                              
    else

                   
        for ((I=0; I<${#HOSTS[@]}; I+=1))   # processa os usuários da classe 1
        do
            REPUTACAO=$(freechains --host=localhost:${HOSTS[$I]} chain '#chat' reps ${PUBKEY[$I]} )
            CADEIA=($(freechains --host=localhost:${HOSTS[$I]} chain '#chat' consensus))
                        
            SALTAR=1

            for BLOCO in ${CADEIA[*]}
            do
                if [[ $BLOCO = $1 ]] # O nó já $1 esse bloco e o usuário pode interagir
                then
                    SALTAR=0
                    break
                fi
            done
            
            if [[ $REPUTACAO < 1 || $SALTAR = 1 ]]      # o usuário não tem reputação para interagir com a postagem 
            then                                        # e/ou ainda não conhece $1
                continue
            else
            
                case $OP in
                    1)          # like viral
                        freechains --host=localhost:${HOSTS[$I]} chain '#chat' like $1 --sign=${PRIKEY[$I]} 
                    ;;
                    2)          # dislike viral
                        freechains --host=localhost:${HOSTS[$I]} chain '#chat' dislike $1 --sign=${PRIKEY[$I]} 
                    ;;
                esac
            fi
        done
                     
        for ((I=${#HOSTS[@]}; I<${#USUARIOS[@]}; I+=1))   # processa os usuários da classe 2
        do
            determinar_porta $I
            
            REPUTACAO=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' reps ${PUBKEY[$I]} )
            CADEIA=($(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' consensus))
            
            SALTAR=1

            for BLOCO in ${CADEIA[*]}
            do
                if [[ $BLOCO = $1 ]] # O nó já recebeu $1 e o usuário pode interagir
                then
                    SALTAR=0
                    break
                fi
            done
            
            if [[ $REPUTACAO < 1 || $SALTAR = 1 ]]      # o usuário não tem reputação para interagir com a postagem 
            then                                        # e/ou ainda não conhece $1
                continue
            else
            
                case $OP in
                    1)          # like viral
                        freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' like $1 --sign=${PRIKEY[$I]} 
                    ;;
                    2)          # dislike viral
                        freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' dislike $1 --sign=${PRIKEY[$I]}
                    ;;
                esac
            fi
        done
    fi
}


#////////////////////////////////////////////////////////////////////

perguntar() {

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Procedimento responsável por simular a ação do usuário $1 postando uma pergunta no fórum.
    #
    # É uma das interações simuladas no script

    determinar_porta $1
    
    CLASSE=$1

    if [[ $CLASSE -ge ${#HOSTS[@]} ]]
    then
        CLASSE=$((1 + $[$RANDOM%4])) 
    fi

    case $CLASSE in
        0)          # Pioneiro
            OP=24 
        ;;
        1)          # Entusiasta
            OP=$((23 + $[$RANDOM%2])) 
        ;;
        2)          # Curioso
            return
        ;;
        3)          # Regular
            OP=23
        ;;
        4)          # Newbie
            OP=$((22 + $[$RANDOM%2])) 
        ;;
        5)          # Troll
            OP=21
        ;;
    esac

    POST=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' post inline "$OP Texto da pergunta do ${USUARIOS[$1]}" --sign=${PRIKEY[$1]})
    
    if [[ $POST =~ [0-9]{1,}\_[a-zA-Z0-9]{64} ]]    # regex para garantir que o array só contenha hash de bloco
    then
        ASKS[${#ASKS[@]}]=$POST                     # registra a pergunda na estrutura de dados que guarda as perguntas não respondidas
        enviar_atualizacao $1
        viral $POST
        enviar_atualizacao $1
    fi
    
}

#////////////////////////////////////////////////////////////////////

validar_post() {

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Procedimento responsável por simular o usuário $1 tratando as postagens bloqueadas com objetivo
    # de permitir a participação de usuários sem reputação suficiente para realizar interações. Onde
    # $1 sincroniza sua cadeia e analisa os blocos bloqueados.
    #
    # É uma das interações simuladas no script

    if [[ -z "$1" ]]
    then
        for (( j=0; j < 3; j+=1))   # define se a iteração será realizada e, se $1 não for fornecido,
        do                          # quem será o usuário responsável
            ID=$(( $[$RANDOM % ${#USUARIOS[@]}] ))
            REPUTACAO=$(freechains chain '#chat' reps ${PUBKEY[$ID]} )
            if [[ $REPUTACAO < 1 ]]
            then
                continue
            else
                break
            fi
            return
        done
    else
        ID=$1
    fi


    ## Sincronizando a cadeia ##

    buscar_atualizacao $ID    

    ## Buscando blocos bloqueados ##

    unset BLOCKEDS
    declare -a BLOCKEDS 
    BLOCKEDS=($(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' heads blocked))
    sleep 1

    if [ ${#BLOCKEDS[@]} = 0 ]     
    then  # nada a fazer
        return
    else  # analisar o conteúdo do post
        for I in ${BLOCKEDS[*]}
        do
            PAYLOAD=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' get payload ${I} )
            OP=${PAYLOAD:0:2}
            REPUTACAO=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' reps ${PUBKEY[$ID]} )

            if [[ $REPUTACAO < 1 ]]
            then
                break
            fi

            case $OP in
                21|31)          # Trolagens
                    freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' dislike ${I} --sign=${PRIKEY[$ID]}
                ;;
                22|23|24)       # Perguntas válidas
                    freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' like ${I} --sign=${PRIKEY[$ID]} 
                ;;
                32|33|34|35|36) # Respostas válidas
                    freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' like ${I} --sign=${PRIKEY[$ID]} 
                ;;

            esac
       done
    fi

    ## Disseminando o novo estado da cadeia ##

    enviar_atualizacao $ID    

}

#////////////////////////////////////////////////////////////////////

moderador() {

    ###############################
    ####  $1 ID do usuário     ####  
    ####  $2 hash do bloco     ####
    ####  $3 tipo de postagem  ####    
    ###############################

    # Processo interno da simulação que executa as ações do perfil moderador durante
    # a interação responder(), única função onde moderador() é utilizado.
    #
    # É uma atividade operacional da simulação
    
    case $3 in

        22|23|24)   # Perguntas válidas
            freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' post inline "32 Respondendo ao post $2" --sign=${PRIKEY[$1]} 
        ;;
        21|31)      # Trolagens
            freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' dislike $2 --sign=${PRIKEY[$1]}
            return
        ;;
        33)         # Resposta incorreta
            freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' post inline "36 Corrigindo o post $2" --sign=${PRIKEY[$1]} 
        ;;
        34)         # Resposta parial
            freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' post inline "35 Complementando o post $2" --sign=${PRIKEY[$1]} 
        ;;
    esac

}

#////////////////////////////////////////////////////////////////////

responder() {

    ############################
    ####  $1 ID do usuário  ####  
    ############################

    # Procedimento responsável por simular a ação do usuário $1 postando uma resposta a uma pergunta do fórum.
    #
    # É uma das interações simuladas no script

    determinar_porta $1

    CLASSE=$1

    for ((j=0; j<${#ASKS[@]}; j+=1))
    do
        PAYLOAD=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' get payload ${ASKS[$j]} )
        OP=${PAYLOAD:0:2}

        if [[ $CLASSE -ge ${#HOSTS[@]} ]]
        then
            CLASSE=$((1 + $[$RANDOM%4])) 
        fi
        
        case $CLASSE in
            0)          # Pioneiro
                moderador $1 ${ASKS[$j]} $OP
                POST=''
            ;;
            1)          # Entusiasta
                moderador $1 ${ASKS[$j]} $OP
                POST=''
            ;;
            2)          # Curioso
                return
            ;;
            3)          # Regular
                if [[ $OP = 22 || $OP = 23 ]]
                then
                    freechains --host=localhost:${HOSTS[HOST]} chain '#chat' post inline "32 Respondendo ao post ${ASKS[$j]}" --sign=${PRIKEY[$1]}
                    POST=''
                elif [[ $OP = 24 ]]
                then
                    POST=$(freechains --host=localhost:${HOSTS[HOST]} chain '#chat' post inline "34 Respondendo ao post ${ASKS[$j]}" --sign=${PRIKEY[$1]})
                else
                    continue
                fi
            ;;
            4)          # Newbie
                if [[ $OP = 23 ]]
                then
                    POST=$(freechains --host=localhost:${HOSTS[HOST]} chain '#chat' post inline "33 Respondendo ao post ${ASKS[$j]}" --sign=${PRIKEY[$1]})
                else
                    continue
                fi
            ;;
            5)          # Troll
                if [[ $OP = 21 || $OP = 31 ]]
                then
                    continue
                else
                    POST=$(freechains --host=localhost:${HOSTS[HOST]} chain '#chat' post inline "31 Trolando o post ${ASKS[$j]}" --sign=${PRIKEY[$1]})
                fi
            
                REPUTACAO=$(freechains --host=localhost:${HOSTS[HOST]} chain '#chat' reps ${PUBKEY[$1]})
            
                if [[ $REPUTACAO < 1 ]]
                then
                    POST=''
                fi
            ;;
        esac
        
        if [[ $POST =~ [0-9]{1,}\_[a-zA-Z0-9]{64} ]] # regex para garantir que o array só contenha hash de bloco
        then
            ASKS[${#ASKS[@]}]=$POST
        fi

        if ! [[ $OP = 21 || $OP = 31 ]]  # Não é trolagem
        then
            unset ASKS[$j]
            ASKS=( ${ASKS[@]} )
        fi
        enviar_atualizacao $1
        if [[ $POST =~ [0-9]{1,}\_[a-zA-Z0-9]{64} ]] # POST é um bloco
        then
            viral $POST
        fi
        enviar_atualizacao $1
        break # responderá uma pergunta por rodada
    done
}

#////////////////////////////////////////////////////////////////////

listar_status() {

    # Processo interno da simulação responsável por listar em tela o status da cadeia no
    # momento da sua execução.
    #
    # É uma atividade operacional da simulação com o objetivo de permitir o acompanhamento
    # da evolução do fórum.


    for ((USER=0; USER<${#USUARIOS[@]}; USER+=1))
    do

    determinar_porta $USER

    CADEIA=($(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' consensus))
    REPUTACAO=$(freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' reps ${PUBKEY[$USER]})
    
    echo "${USUARIOS[$USER]} tem reputação $REPUTACAO e sua cadeia, ${#CADEIA[@]} blocos. "    
    echo

    done
}

#////////////////////////////////////////////////////////////////////

parar_hosts() {


    # Processo interno da simulação responsável por parar os deamons que servem os nós.
    #
    # É uma atividade operacional da simulação.


    for I in ${HOSTS[*]}
    do
        freechains-host stop --port=${I} 
    done
}




################################# Inicialização do ambiente #################################


## Subindo os hosts ##

for ((I=0; I<${#HOSTS[@]}; I+=1))
do

    nohup freechains-host --port=${HOSTS[$I]} start /tmp/simul/${USUARIOS[$I]} > /dev/null &
    sleep 5    # para garantir que os deamons subiram e estão em execução antes de requisitarmos serviços 

done


## Gerando as chaves ##


for ((USER=0; USER<${#USUARIOS[@]}; USER+=1))
do

    KEYS=( $(freechains keys pubpvt "Está é a senha forte para o usuário ${USUARIOS[$USER]} " ) )
    sleep 5     # para garantir que as chaves foram geradas. 
    PUBKEY[$USER]=${KEYS[0]}
    PRIKEY[$USER]=${KEYS[1]}

done


EPOCH=$(freechains-host now) #registrando o tempo 0


## Criando o Forum ##

freechains chains join '#chat' ${PUBKEY[0]}
freechains chain '#chat' post inline "Texto de boas vindas e abertura do Fórum" --sign=${PRIKEY[0]}
freechains chain '#chat' post inline "Texto explicando as regras, objetivos e funcionamento do fórum" --sign=${PRIKEY[0]}
freechains chain '#chat' post inline "Texto apresentando o pioneiro" --sign=${PRIKEY[0]}


## Simulado a entrada dos usuários da 1ª Classe ##


for ((I=1; I<${#HOSTS[@]}; I+=1))
do
    freechains --host=localhost:${HOSTS[$I]} chains join '#chat' ${PUBKEY[0]}
    freechains --host=localhost:${HOSTS[$I]} peer localhost:8330 recv '#chat'
    freechains --host=localhost:${HOSTS[$I]} chain '#chat' post inline "Olá, sou ${USUARIOS[$I]} e meu host é localhost:${HOSTS[$I]}" --sign=${PRIKEY[$I]}
    freechains --host=localhost:${HOSTS[$I]} peer localhost:8330 send '#chat'
done

## Simulado a entrada dos usuários da 2ª Classe ##

for ((I=${#HOSTS[@]}; I<${#USUARIOS[@]}; I+=1))
do
    determinar_porta $I

    freechains --host=localhost:${HOSTS[$HOST]} peer localhost:8330 recv '#chat'
    freechains --host=localhost:${HOSTS[$HOST]} chain '#chat' post inline "Olá, sou ${USUARIOS[$I]} e meu host é localhost:${HOSTS[$HOST]}" --sign=${PRIKEY[$I]}
    freechains --host=localhost:${HOSTS[$HOST]} peer localhost:8330 send '#chat'
done

## Simulado o pioneiro adimitindo os novos usuários ##

BLOCKEDS=($(freechains chain '#chat' heads blocked))
for I in ${BLOCKEDS[*]}
do
    freechains chain '#chat' get payload ${I}
    freechains chain '#chat' like ${I} --sign=${PRIKEY[0]}
done

freechains chain '#chat' post inline "Texto de saudações, boas vindas ao fórum e orientações inciais" --sign=${PRIKEY[0]}

enviar_atualizacao 0


####################################################################################################
#################################### Simulação do fórum público ####################################
####################################################################################################

## Atualizando a base do tempo para a simulação ##

EPOCH=$(( $EPOCH + $DAY ))
TEMPO=$EPOCH

## Início da simulação ##

for ((MES=1; MES<4; MES+=1))                	
do
    echo
    echo "Início do mês $MES"
    echo
    
    saltar_tempo $TEMPO
    listar_status

    for ((DIA=1; DIA<31; DIA+=1))
    do
        echo "Dia $DIA do mês $MES da simulação - 00:00h"

        if [[  $[ $DIA%10 ] =  0 ]]
        then
            listar_status
        fi

        for ((HH=0; HH<24; HH+=12))
        do
            echo "São $HH:00 horas"
            
            TEMPO=$(($TEMPO + $TWELVE_HOURS))
            
            for ((count=0; count<$(( $[$RANDOM%2])) ; count+=1))
            do
                for ((USER=0; USER<${#USUARIOS[@]}; USER+=1))
                do
                    SALTAR=$(( $(($RANDOM%4)) / 3 )) 
                    if [[ $SALTAR = 0 ]]
                    then
                        echo
                        continue
                    else
                        TP=$(( $[$RANDOM%6] ))
                        case $TP in
                            0)          # Ler
                                buscar_atualizacao $USER 
                            ;;
                            1|2|3)      # Perguntar
                                perguntar $USER
                                echo
                                break  # interromper o laço neste ponto torna a simulação bem mais rápida
                                #       # mas não altera em nada a dinâmica do processo que este script se
                                #       # propõem a simular.
                            ;;
                            4|5)        # Responder
                                if [[ ${#ASKS[@]} > 0 ]]
                                then
                                    responder $USER
                                fi
                            ;;
                        esac
                        echo
                    fi
                done
            done
            saltar_tempo $TEMPO
        done
        if [[ $MES = 1 ]]   # início do fórum, o pioneiro precisa impulsionar a participação
        then
            validar_post $(( $DIA/16 * $[$RANDOM%2] ))
        else                # fórum já está consolidado
            validar_post
        fi
        
    done
    echo
    listar_status
    echo
    echo "Final do mês $MES"
    echo
done

parar_hosts

