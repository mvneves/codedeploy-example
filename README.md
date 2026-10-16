# AWS CodeDeploy Example

Aplicação Flask mínima implantada numa instância EC2 com o AWS CodeDeploy, disparado pelo GitHub Actions.

Os passos abaixo foram pensados para o AWS Academy Learner Lab, onde não é possível criar *roles* IAM: a instância usa o
perfil **LabInstanceProfile** e o CodeDeploy usa a role **LabRole** como *service role*. Use a região `us-east-1`.

## Estrutura

| Arquivo | Função |
|---|---|
| `hello.py` | Aplicação Flask (porta 8080) |
| `appspec.yml` | Diz ao CodeDeploy para onde copiar os arquivos e quais *scripts* executar |
| `scripts/install_dependencies.sh` | *Hook* `BeforeInstall`: instala o Flask |
| `scripts/start_server.sh` | *Hook* `ApplicationStart`: inicia a aplicação |
| `scripts/stop_server.sh` | *Hook* `ApplicationStop`: encerra a versão anterior |
| `.github/workflows/deploy.yml` | Envia a revisão ao S3 e cria a implantação a cada *push* na `main` |

## 1. Criar a instância EC2

1. Lance uma instância **Ubuntu Server 24.04** (`t2.micro` ou `t3.micro`).
2. Em **Advanced details > IAM instance profile**, escolha **LabInstanceProfile**.
3. No *security group*, libere as portas 22 (SSH) e 8080 (aplicação).
4. Adicione a *tag* `Name` = `codedeploy-example` (o grupo de implantação encontra a instância por ela).
5. Em **User data**, cole o *script* que instala o agente do CodeDeploy:

   ```bash
   #!/bin/bash
   apt-get update
   apt-get install -y ruby-full wget
   cd /home/ubuntu
   wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
   chmod +x ./install
   ./install auto
   systemctl start codedeploy-agent
   ```

   Para conferir depois, conecte na instância e rode `sudo systemctl status codedeploy-agent`.

## 2. Criar o bucket, a aplicação e o grupo de implantação

Pelo AWS CLI (ou pelo console, em **CodeDeploy > Applications**, com *compute platform* **EC2/On-premises**):

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Bucket para as revisões (o nome precisa ser único no mundo)
aws s3 mb s3://codedeploy-example-$ACCOUNT_ID

aws deploy create-application --application-name codedeploy-example

aws deploy create-deployment-group \
    --application-name codedeploy-example \
    --deployment-group-name codedeploy-example-group \
    --service-role-arn arn:aws:iam::$ACCOUNT_ID:role/LabRole \
    --ec2-tag-filters Key=Name,Value=codedeploy-example,Type=KEY_AND_VALUE \
    --deployment-config-name CodeDeployDefault.AllAtOnce
```

No console, escolha **LabRole** como *service role* e desmarque o *load balancer*.

## 3. Configurar o GitHub Actions

Faça um *fork* deste repositório e, em **Settings > Secrets and variables > Actions**, cadastre:

| Tipo | Nome | Valor |
|---|---|---|
| *Secret* | `AWS_ACCESS_KEY_ID` | `aws_access_key_id` de **AWS Details** no Learner Lab |
| *Secret* | `AWS_SECRET_ACCESS_KEY` | `aws_secret_access_key` |
| *Secret* | `AWS_SESSION_TOKEN` | `aws_session_token` |
| *Variable* | `S3_BUCKET` | Nome do bucket criado no passo 2 |

As credenciais do Learner Lab mudam a cada sessão: atualize os três *secrets* sempre que iniciar o laboratório.

A cada *push* na `main` (ou em **Actions > Deploy com CodeDeploy > Run workflow**), o *workflow* empacota o
repositório, envia o pacote ao S3 e cria a implantação. Quando terminar, acesse `http://<IP público da instância>:8080`.

## Implantação manual pelo CLI

```bash
aws deploy push --application-name codedeploy-example \
    --s3-location s3://<bucket>/codedeploy-example/app.zip --source .

aws deploy create-deployment --application-name codedeploy-example \
    --deployment-group-name codedeploy-example-group \
    --s3-location bucket=<bucket>,key=codedeploy-example/app.zip,bundleType=zip
```

## Problemas comuns

- **A implantação fica em *Pending* ou falha sem eventos:** o agente não está rodando ou a instância não usa o
  **LabInstanceProfile**.
- **Falha no *hook* `BeforeInstall`:** veja o log em `/opt/codedeploy-agent/deployment-root/deployment-logs/`.
- **Erro de credencial no GitHub Actions:** a sessão do Learner Lab expirou; atualize os *secrets*.
