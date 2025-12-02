**Reset Trial do CrossOver no Linux**

Guia seguro para realizar uma reinstalação limpa

Este repositório contém instruções sobre como realizar uma reinstalação limpa do CrossOver no Linux para fins de diagnóstico, testes controlados ou solução de problemas.

⚠️ Não incentiva, não instrui e não apoia violação de licenças, pirataria ou extensão ilegal de períodos trial.

O objetivo é apenas remover arquivos residuais que podem permanecer após a remoção normal do software, permitindo uma reinstalação limpa para testes autorizados.


**📌 Aviso Importante**

CrossOver é um software pago e protegido por direitos autorais.
➡️ Use este guia apenas se você tem permissão legítima, como:

Avaliação dentro de um período trial válido

Testes corporativos autorizados

Reinstalação para correção de bugs

Alternar entre versões para QA

Este repositório não fornece métodos para burlar licenciamento ou estender o trial além do permitido pela CodeWeavers.



**🧽 1. Desinstalar o CrossOver**

Remova o pacote normalmente, conforme sua distribuição:

Debian/Ubuntu
sudo apt remove crossover
sudo apt purge crossover

Fedora/RHEL
sudo dnf remove crossover

Arch-based
sudo pacman -Rns crossover



**🗑️ 2. Remover arquivos residuais**

O CrossOver cria diretórios de configuração, logs e garrafas (bottles).
Remova apenas se deseja realmente apagar todos os dados:

rm -rf ~/.cxoffice
rm -rf ~/.config/crossover
rm -rf ~/.local/share/crossover
rm -rf ~/.cache/crossover


Se você instalou versões antigas ou betas:

rm -rf ~/.codeweavers
rm -rf ~/.cxoffice-beta



**🔄 3. Reinstalar o CrossOver**

Baixe novamente o instalador oficial do site da CodeWeavers:

👉 https://www.codeweavers.com/crossover

E instale:

sudo dpkg -i crossover_*.deb   # Debian/Ubuntu
sudo rpm -i crossover-*.rpm    # RedHat/Fedora



**🧪 4. Verificar se a instalação está limpa**

Após reinstalar, rode:

crossover


E confirme que:

Bottles não foram restauradas

Preferências voltaram ao padrão

Logs foram resetados



**📝 Notas Finais**

Isso não redefine licença — apenas remove dados locais.

O trial é controlado pelo mecanismo oficial de licenciamento da CodeWeavers.

Para extensões, renovações ou solicitações especiais, utilize sempre o suporte oficial.
