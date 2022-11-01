# P2P - Simulação de Fórum Público

Script para simular o funcionamento de um fórum público executado sobre o [Freechains](https://github.com/Freechains/README). <br><br>

### _Simule o funcionamento de um fórum público por 3 meses..._

Atividade 3.4 da Disciplina Tópicos Especiais em Redes de Telecomunicações - Sistemas Peer-to-Peer.<br> <br>
Simular três meses de atividade de um fórum público com:<br><br>
- comando `freechains-host now <timestamp>` para simular a passagem do tempo;<br>
- múltiplos _nós_ e múltiplos usuários divididos entre os _nós_;<br>
- variedade no nível de atividade e perfil dos usuários;<br>
- variedade na qualidade das postagens para a despertar o uso _likes & dislike_.<br>
<hr>

## A simulação

Trata-se de um [script bash](https://pt.wikipedia.org/wiki/Shell_script) que, utilizando os [comandos do protocolo freechains](https://github.com/Freechains/README/blob/master/docs/cmds.md), tem por objetivo simular três meses de interação entre participantes de um fórum público.<br>

### O Escopo

O escopo da atividade é a simulação das interações dos usuários para observar a evolução do fórum, com destaque para:<br>

- transferência de reputação através de _likes & dislike_;<br>
- aumento orgânico da quantidade de postagens;<br>
- evolução da reputação dos participantes.<br><br>

Mas, não fazem parte do escopo:<br>

- a análise semântica do conteúdo das mensagens;<br>
- a classificação das postagens com base na semântica de seu _payload_;<br>
- a classificação dos participantes a partir da semântica de suas interações.

### O Fórum
Será um fórum de perguntas e respostas onde usuários fazem e respondem perguntas. Mas, como a semântica não faz parte do escopo, o tema do fórum é irrelevante e, por isso, ele não é explicitado.<br><br>
E, como qualquer postagem fora do tema do grupo será tratada como [spam](https://pt.wikipedia.org/wiki/Spam) pelos demais participantes, assume-se que essa análise é foi feita pelos usuários e, para esta simulação todas as mensagens já contam com sua classificação semântica. 

### Os usuários

A simulação conta com duas classes de usuários: uma para aqueles cujas interações seguem um perfil definido e a outra, para aqueles cujas iterações podem ser agrupadas em mais de um perfil.<br>

- Classe 1<br><br>

Nome | ID | Descrição
:------------ | :-----: | :----------------------
Pioneiro | 0 | Criador do fórum, principal interessado em impulsionar sua utilização
Entusiasta | 1 | Usuário ativo, com perfil de moderador e suas interações são relevantes 
Curioso | 2 | Lê o chat com regularidade mas não interage       
Regular | 3 | Usuário ativo e suas interações são normais 
Newbie | 4 | Usuário com bom nível de interação mas participações simples
Troll | 5 | Usuário ativo mas suas interações são consideradas trolagens
<br>

- Classe 2  <br><br>

Nome | ID | Descrição
:------------ | :-----: | :----------------------
QualquerUm | 6 | Usuário com perfil de interação variada
QualquerDois | 7 | Usuário com perfil de interação variada
QualquerTres | 8 | Usuário com perfil de interação variada
<br>

### A distribuição dos nós

É atribuído um _nó_ para cada usuário da Classe 1 e cada usuário da Classe 2 compartilha um _nó_ com um dos usuários da Classe 1, com exceção do Pioneiro, cujo _nó_ é exclusivo.<br>

### As interações
A dinâmica do fórum é simulada com o uso da função `RANDOM` para determinar  usuário, tipo e quantidade de interações ocorrerão a cada rodada.<br><br>
Com meses de trinta dias e duas rodadas por dia, a simulação conta com as seguintes interações:<br> 

- Perguntar  - Posta uma pergunta no fórum.
- Responder  - Posta uma resposta para uma pergunta do fórum.
- Consultar  - Busca os novos blocos dos demais _nós_ da rede para atualizar a sua cadeia.
- Disseminar - Envia os novos blocos para os demais _nós_ da rede para disseminar a atualização de sua cadeia.
- Validar    - Trata as postagens [bloqueadas](https://github.com/Freechains/README/blob/master/docs/blocks.md) permitindo participação de usuários sem reputação.
- Viralizar  - Trata as postagens virais utilizando _likes & dislike_.<br>

### As limitações

Além do "não escopo", o _script_ não trata o uso _likes & dislike_ em suas próprias postagens porque, embora o protocolo não permita essa ação, sua execução não quebra a simulação.<br>
<br>Também não há simulação de réplicas e tréplicas, reação dos autores às respostas e aos _likes & dislike_.<br>

### Resultados
Foi simulado um fórum público, com usuários participativos e um pioneiro disposto a fomentar a participação dos novos usuários através da transferência de reputação com o uso de _likes_ em suas postagens.<br>
<br>Esse ambiente permitiu o crescimento do fórum, observado no:<br>

- aumento da cadeia, verificada com o [comando](https://github.com/Freechains/README/blob/master/docs/cmds.md#chain-consensus) `freechains chain <name> consensus`<br>
- aumento da reputação total do fórum, tomada pelo somatório da reputação de seus membros.<br>

Mesmo a existência de usuários abusivos não prejudicou o funcionamento do fórum pois o sistema de reputação o protegeu, preservando a qualidade das postagens e mantendo o fórum ativo.<br>
<br>Outro ponto interessante é o incentivo a participação de qualidade pois os usuários mais ativos terminaram com maior reputação, permitindo mais postagens.<br>
<br>Já os usuários com baixa participação não conseguiram aumentar sua reputação e, com isso, suas possibilidades de interagir acabaram limitadas.<br>
<hr>

## Como executar

#### Pré-requisitos

- Instalar o [Freechains](https://github.com/Freechains/README#install).<br>
- Adicionar permissão de execução para o _script_: `chmod +x simul.sh`<br>

#### Rodar a simulação 


Basta executar o _script_: `simul.sh`.<br>
Mas, para facilitar a análise dos resultados, sugerimos redirecionar a saída para um arquivo: `./simul.sh > ./simul.log`<br><br>


#### Limpeza

Os dados do Freechains são gravados no diretório fornecido como parâmetro para o [comando](https://github.com/Freechains/README/blob/master/docs/cmds.md#start) `freechains-host start <dir>`.
<br><br>Como a simulação utiliza o caminho `/tmp/simul/*`, para remover os arquivos e executar uma nova simulação basta executar o comando:<br>

```bash
rm -fr /tmp/simul/
```
<br>
<hr>
## Resultados
